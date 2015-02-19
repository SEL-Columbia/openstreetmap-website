require 'OSM/Export/KML'
require 'geo_ruby'
require 'net/http'
require 'uri'

# require 'securerandom'

# This seems odd, but we're patching the Net::HTTP class
# to set a longer timeout of 10 minutes
module Net
  class HTTP
    alias old_initialize initialize

    def initialize(*args)
      old_initialize(*args)
      @read_timeout = 10*60     # 10 minutes
    end
  end
end

class ExportController < ApplicationController

  before_filter :authorize_web
  before_filter :set_locale

  caches_page :embed

  #When the user clicks 'Export' we redirect to a URL which generates the export download
  def finish
    bbox = BoundingBox.from_lon_lat_params(params)
    format = params[:format]

    if format == "osm"
      #redirect to API map get
      redirect_to "/api/#{API_VERSION}/map?bbox=#{bbox}"

    elsif format == "kml"
      # ISSUES:  
      # A)  This won't scale as it pulls the entire osm xml into memory in order to 
      #     translate into kml. 
      # B)  For kml format, we don't do a redirect as we do for osm format.  It could
      #     be more consistent
      #
      # TODO:  Write kml response into cgimap call so that it can be streamed directly to client?  

      uuid = SecureRandom.hex
      rulefilename = File.join(Rails.root, 'config', 'base-kml.oxr')
      outfilename = [uuid, "grid.kml"].join("_")
      osmfilename = [uuid, "grid.osm"].join("_")
      
      tmp_outfilename = File.join("tmp", outfilename)
      tmp_osmfilename = File.join("tmp", osmfilename)
      mapper = OSM::Export::KML.new(tmp_outfilename)
 
      # Use if we want to retrieve map xml from alternative URL (via cgimap for speed)
      uri = URI.parse(SERVER_MAP_URL + "/api/#{API_VERSION}/map?bbox=#{bbox}")
      # 
      ## handle exception?  
      map_osm_response = Net::HTTP.get_response(uri)

      File.open(tmp_osmfilename,'w') do |f|
        f.write map_osm_response.body
        f.close
      end

      mapper.instance_eval(File.read(rulefilename), rulefilename)
      
      # Use to retrieve the map xml from this ruby/rails app 
      # doc = map_xml(bbox)
      # write to file for now to be compatible with osmlib export api
      # tmp_osmfile = File.open(tmp_osmfilename, "w")
      # doc.save(tmp_osmfilename, :indent => true)
      # tmp_osmfile.close 

      parser = OSM::Export::Parser.new(tmp_osmfilename, mapper)
      # debugger
      parser.parse
  
      mapper.commit

      response.headers["Content-Disposition"] = "attachment; filename=\"map.kml\""
      render :text => File.read(tmp_outfilename), :content_type => "text/xml"
       
    elsif format == "mapnik"
      #redirect to a special 'export' cgi script
      format = params[:mapnik_format]
      scale = params[:mapnik_scale]

      redirect_to "http://render.openstreetmap.org/cgi-bin/export?bbox=#{bbox}&scale=#{scale}&format=#{format}"
    end
  end

  def embed
  end
end

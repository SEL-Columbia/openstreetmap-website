require 'OSM/Export/KML'
require 'geo_ruby'

# require 'securerandom'

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
      uuid = SecureRandom.uuid
      rulefilename = File.join(Rails.root, 'config', 'base-kml.oxr')
      outfilename = [uuid, "grid.kml"].join("_")
      osmfilename = [uuid, "grid.osm"].join("_")
      
      tmp_outfilename = File.join("tmp", outfilename)
      tmp_osmfilename = File.join("tmp", osmfilename)
      # debugger
      mapper = OSM::Export::KML.new(tmp_outfilename)
      mapper.instance_eval(File.read(rulefilename), rulefilename)
      
      doc = map_xml(bbox)
      # debugger
      # write to file for now to be compatible with osmlib export api
      # tmp_osmfile = File.open(tmp_osmfilename, "w")
      doc.save(tmp_osmfilename, :indent => true)
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

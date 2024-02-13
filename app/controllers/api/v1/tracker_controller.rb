require 'net/http'
require 'uri'
require 'nokogiri'
require 'byebug'
require 'json'

class Api::V1::TrackerController < ApplicationController
  def show
   imie = params[:id]

  # Defining Some Default Params 
    uri = URI.parse("https://zipnet.delhipolice.gov.in/index.php")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/x-www-form-urlencoded"
    request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    request["Accept-Language"] = "en-GB,en-US;q=0.9,en;q=0.8"
    request["Cache-Control"] = "max-age=0"
    request["Connection"] = "keep-alive"
    request["Cookie"] = "ln=en; PHPSESSID=sj7e6o7190bqp1bd5i173isql1"
    request["Origin"] = "https://zipnet.delhipolice.gov.in"
    request["Referer"] = "https://zipnet.delhipolice.gov.in/index.php?page=missing_mobile_phones_search&criteria=search"
    request["Sec-Fetch-Dest"] = "document"
    request["Sec-Fetch-Mode"] = "navigate"
    request["Sec-Fetch-Site"] = "same-origin"
    request["Sec-Fetch-User"] = "?1"
    request["Upgrade-Insecure-Requests"] = "1"
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
    request["Sec-Ch-Ua"] = "\"Not A(Brand\";v=\"99\", \"Google Chrome\";v=\"121\", \"Chromium\";v=\"121\""
    request["Sec-Ch-Ua-Mobile"] = "?0"
    request["Sec-Ch-Ua-Platform"] = "\"macOS\""
    request.set_form_data(
      "I4.x" => "28",
      "I4.y" => "6",
      "criteria" => "search",
      "page" => "missing_mobile_phones_search",
      "registration_number" => imie,
    )

    req_options = {
      use_ssl: uri.scheme == "https",
    }
    
    begin
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    
      if response.code.to_i == 200
        doc = Nokogiri::HTML(response.body)
        target_table = doc.css('#AutoNumber1')[3]
        _data_found = self.checktbl(target_table)
        data = {}
        if _data_found
          our_table = target_table.css("#AutoNumber6")
          parent = our_table.children[1].children[1].children[0] rescue ''
          data[:fir_dd_gdNumber] = parent.children[1].children[3].text rescue ''
          data[:state] = parent.children[1].children[7].text rescue ''
          data[:fir_dd_gdDate] = parent.children[3].children[3].text.strip rescue ''
          data[:district] = parent.children[3].children[7].text.strip rescue ''
          data[:mobile_type] =  parent.children[5].children[3].text.strip rescue ''
          data[:police_station] = parent.children[5].children[7].text.strip rescue ''
          data[:mobile_make] = parent.children[7].children[3].text.strip rescue ''
          data[:missing_stole_date] = parent.children[9].children[3].text.strip rescue ''
          data[:imie] = parent.children[9].children[7].text.strip rescue ''
          data[:status] = parent.children[13].children[3].text rescue ''
          data[:report_timestamp_on_zipnet] = parent.children[13].children[7].text rescue ''
          json_data = data.to_json
          render json: json_data
        else
          render json: { status: 200, message: "data not found for this IMIE number"}
        end
      else
        render json: { status: response.code}
      end
    
    rescue Net::OpenTimeout => e
      render json: { status: 500, message: "Failed to connect to the server: #{e.message}"}
    end
  end

  private

  def checktbl(tbl)
    _data_found = false
    if tbl
      # Iterate through each row (tr) in the table
      tbl.css('tr').each do |row|
        # Check if any td or th contains the text 'FIR'
        if row.css('td, th').any? { |cell| cell.text.include?('Police Station') }
          # Print the HTML content of the row if it contains 'FIR'
          _data_found = true
        end
      end
    else
      _data_found = false
    end
    _data_found
  end
end

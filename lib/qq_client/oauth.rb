require "digest/md5"
require "base64"

module QqClient
  class Oauth
    API_URL = "https://graph.qq.com/"

    def initialize(access_token)
      config = QqClient::Config::load_config(nil, nil, nil)
      @app_key = config[:app_key]
      @access_token = access_token
    end

    def get(uid, path, parameters = {})
      parameters.merge!(openid: uid,access_token: @access_token,oauth_consumer_key: @app_key)
      JSON.parse RestClient.get(api_url(path), :params => parameters)
    end

    def post(uid, path, parameters = {})
      parameters.merge!(openid: uid,access_token: @access_token,oauth_consumer_key: @app_key)
      JSON.parse RestClient.post(api_url(path), parameters)
    end

    def get_uid(path, parameters = {})
      parameters.merge!(access_token: @access_token,oauth_consumer_key: @app_key)
      callback_function = RestClient.get(get_uid_url(path, parameters))
      callback_function.match(/"openid":([^\/.]*)$/).to_a.second.split('"').second
    end

    ######################################################
    #
    # @param string $signed_request 应用框架在加载iframe时会通过向Canvas URL post的参数signed_request
    #
    #####################################################
    def self.parse_signed_request(signed_request)
      encoded_sig, payload = signed_request.split(".")
      sig = Base64.decode64_url(encoded_sig)
      begin
        data = JSON.parse(Base64.decode64_url(payload))
      rescue Exception => e
        return nil
      end
      return nil if data["algorithm"].upcase != "HMAC-SHA256"

      expected_sig = OpenSSL::HMAC.digest("sha256", Config.app_secret, payload)
      (sig != expected_sig) ? nil : data
    end

    private
    def api_url(path)
      path = path.gsub /^\//, ""
      "#{API_URL}#{path}"
    end

    def get_uid_url(path, parameters)
      str = ""
      parameters.each do |p|
        sub_str = (str.empty?) ? "#{p[0]}=#{p[1]}" : "&#{p[0]}=#{p[1]}"
        str = str + sub_str
      end
      "#{api_url(path)}?#{str}"
    end

  end
end

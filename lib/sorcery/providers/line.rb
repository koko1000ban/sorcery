module Sorcery
  module Providers
    # This class adds support for OAuth with line.com.
    #
    #   config.line.key = <key>
    #   config.line.secret = <secret>
    #   ...
    #
    class Line < Base
      include Protocols::Oauth2

      attr_accessor :token_url, :user_info_path, :auth_path, :auth_url

      def initialize
        super

        @site           = 'https://access.line.me'
        @user_info_path = 'https://api.line.me/v2/profile'
        @token_url      = 'https://api.line.me/oauth2/v2.1/token'
        @auth_path      = 'oauth2/v2.1/authorize'
        @auth_url       = 'https://access.line.me/oauth2/v2.1/authorize'
      end

      def get_user_hash(access_token)
        response = access_token.get(user_info_path)
        auth_hash(access_token).tap do |h|
          h[:user_info] = JSON.parse(response.body)
          h[:uid] = h[:user_info]['userId'].to_s
        end
      end

      def authorize_url(options = {})

        oauth_params = {
          response_type: 'code',
          client_id: @key,
          redirect_uri: @callback_url,
          scope: 'openid profile',
          nonce: SecureRandom.hex(10),
          state: SecureRandom.hex(10)
        }

        "#{options[:authorize_url]}?#{oauth_params.to_query}"
      end

      # calculates and returns the url to which the user should be redirected,
      # to get authenticated at the external provider's site.
      def login_url(_params, _session)
        authorize_url(authorize_url: auth_url)
      end

      # tries to login the user from access token
      def process_callback(params, _session)
        args = {}.tap do |a|
          a[:code] = params[:code] if params[:code]
        end

        get_access_token(args, token_url: token_url, token_method: :post)
      end
    end
  end
end

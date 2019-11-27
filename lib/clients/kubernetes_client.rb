require 'kubeclient'
require 'uri'

module Clients
  class KubernetesClient
    class Error < StandardError; end
    class MissingCredentialsError < Error; end
    class InvalidURIError < Error; end
    attr_reader :client

    def initialize(api_uri:, version:, service_account:, ca_crt:)
      if [api_uri, service_account, ca_crt].any?(&:blank?)
        raise MissingCredentialsError.new('Missing credentials for Kubernetes')
      end

      auth_options = {
        bearer_token: service_account[:token]
      }
      ssl_options = {
        ca: ca_crt
      }
      @client = Kubeclient::Client.new(
        "https://#{api_uri}",
        version,
        auth_options: auth_options,
        ssl_options:  ssl_options
      )
    end
  end
end
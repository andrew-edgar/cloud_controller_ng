module VCAP::CloudController
  class UpdateRouteDestinations
    class << self
      def add(message, route, apps_hash)
        update(message, route, apps_hash, replace: false)
      end

      def replace(message, route, apps_hash)
        update(message, route, apps_hash, replace: true)
      end

      private

      def update(message, route, apps_hash, replace:)
        existing_route_mappings = route_to_mappings(route)
        new_route_mappings = message_to_mappings(message, route)

        to_add = new_route_mappings - existing_route_mappings
        to_delete = []
        to_delete = existing_route_mappings - new_route_mappings if replace

        RouteMappingModel.db.transaction do
          to_delete.each do |rm|
            route_mapping = RouteMappingModel.find(rm)
            route_mapping.destroy

            Copilot::Adapter.unmap_route(route_mapping)
            update_route_information(route_mapping, apps_hash)
          end

          to_add.each do |rm|
            route_mapping = RouteMappingModel.new(rm)
            route_mapping.save

            Copilot::Adapter.map_route(route_mapping)
            update_route_information(route_mapping, apps_hash)
          end
        end

        route.reload
      end

      def update_route_information(route_mapping, apps_hash)
        app = apps_hash[route_mapping.app_guid]
        app.processes_dataset.where(type: route_mapping.process_type).each do |process|
          ProcessRouteHandler.new(process).update_route_information
        end
      end

      def message_to_mappings(message, route)
        new_route_mappings = []
        message.destinations.each do |dst|
          app_guid = HashUtils.dig(dst, :app, :guid)
          process_type = HashUtils.dig(dst, :app, :process, :type) || 'web'

          new_route_mappings << {
            app_guid: app_guid,
            route_guid: route.guid,
            route: route,
            process_type: process_type,
            app_port: ProcessModel::DEFAULT_HTTP_PORT
          }
        end

        new_route_mappings
      end

      def route_to_mappings(route)
        route.route_mappings.map do |rm|
          {
            app_guid: rm.app_guid,
            route_guid: rm.route_guid,
            process_type: rm.process_type,
            app_port: rm.app_port,
            route: route
          }
        end
      end
    end
  end
end

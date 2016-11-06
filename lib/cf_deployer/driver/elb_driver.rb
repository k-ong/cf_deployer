module CfDeployer
  module Driver
    class ElasticLoadBalancing
      def find_dns_and_zone_id elb_id
        elb = elb_driver.describe_load_balancers({ load_balancer_names: [elb_id]}).first
        load_balancer_descriptions = elb.load_balancer_descriptions.first
        { :canonical_hosted_zone_name_id => load_balancer_descriptions.canonical_hosted_zone_name_id, :dns_name => load_balancer_descriptions.dns_name }
      end

      private

      def elb_driver
        Aws::ElasticLoadBalancing::Client.new
      end

    end
  end
end

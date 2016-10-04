module CfDeployer
  module Driver
    class ElasticLoadBalancing
      def find_dns_and_zone_id elb_id
        elb = elb_driver.describe_load_balancers({ load_balancer_names: [elb_id]}).first
        { :canonical_hosted_zone_name_id => elb.canonical_hosted_zone_name_id, :dns_name => elb.dns_name }
      end

      private

      def elb_driver
        Aws::ElasticLoadBalancing::Client.new
      end

    end
  end
end
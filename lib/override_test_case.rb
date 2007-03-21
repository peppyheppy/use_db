# puts "Overriding Test::Unit::TestCase"

module Test #:nodoc:
  module Unit #:nodoc:
    class TestCase #:nodoc:
      alias_method :rails_setup_with_fixtures, :setup_with_fixtures
      
      def setup_with_fixtures
        return unless defined?(ActiveRecord::Base) && !ActiveRecord::Base.configurations.blank?
        
        if pre_loaded_fixtures && !use_transactional_fixtures
          raise RuntimeError, 'pre_loaded_fixtures requires use_transactional_fixtures' 
        end

        @fixture_cache = Hash.new

        # Load fixtures once and begin transaction.
        if use_transactional_fixtures?
          if @@already_loaded_fixtures[self.class]
            @loaded_fixtures = @@already_loaded_fixtures[self.class]
          else
            load_fixtures
            @@already_loaded_fixtures[self.class] = @loaded_fixtures
          end
          
          for klass in UseDbPlugin.all_use_dbs
          
            # puts "Establishing TRANSACTION for #{klass}..."
            
            klass.send :increment_open_transactions
            klass.connection.begin_db_transaction
          
          end

        # Load fixtures for every test.
        else
          @@already_loaded_fixtures[self.class] = nil
          load_fixtures
        end

        # Instantiate fixtures for every test if requested.
        instantiate_fixtures if use_instantiated_fixtures
      end

      alias_method :rails_teardown_with_fixtures, :teardown_with_fixtures

      def teardown_with_fixtures        
        return unless defined?(ActiveRecord::Base) && !ActiveRecord::Base.configurations.blank?

        for klass in UseDbPlugin.all_use_dbs

          # puts "Finishing TRANSACTION for #{klass}..."

          # Rollback changes if a transaction is active.
          if use_transactional_fixtures? && Thread.current['open_transactions'] != 0
            klass.connection.rollback_db_transaction
            Thread.current['open_transactions'] -= 1
          end
          klass.verify_active_connections!
          
        end
      end
      
      def self.uses_db?
        return true
      end      
    end
  end
end
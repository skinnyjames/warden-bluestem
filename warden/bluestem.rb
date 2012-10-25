module Warden
  module Bluestem
      
    class Config
      attr_accessor :cache_dir, :timeout, :cgi_installdir, :cookie_name
    end
      
    class << self
      def config
        @@config ||= Config.new
      end
      
      def configure(&block)
         block.call(config)
      end
    end

    class Strategy < Warden::Strategies::Base
       #redirect to https on authenticate      
       def authenticate!
       unless request.env['HTTPS'] == 'on'
          redirect! request.url.gsub(/^http:/,'https:') 
          throw :warden
       end
          
          cookie = get_cookie || login!
          
          file, cache_key = cookie.split('~')
          
          cache_file = self.config.cache_dir + file
          login! if !FileTest.exist?(cache_file) || timed_out?(cache_file)
          
          File.open(cache_file, 'r') do |f|
              @netid, @ip, @client_random = f.readline.match(/(\w+)?,((?:\d{1,3}\.){3}\d{1,3}),(#{cache_key})?/)[1..3]
          end
          
          return_user
       end
       
       def return_user
          user = {:netid => @netid, :ip => @ip, :client_random => @client_random } 
          authenticated? ? success!(user) : login!
      end
 
        def config
          Warden::Bluestem.config
        end
 
        def authenticated?
            (@netid and @netid != ('Unknown') and @client_random)
        end
        
        def timed_out?(cache_file)
           config.timeout < Time.new - File.mtime(cache_file)
        end
            
        def login!
              destination = config.cgi_installdir + "lb_login.cgi" + request.fullpath 
              redirect!(destination)
              throw :warden
        end
        
        def get_cookie
              request.cookies[ config.cookie_name ]
        end 
    
    end

    # The Resident Strategy inherits from bluestem.  
    # After authenticating the user's netid, return their user from the resident table    
    class ResidentStrategy < Strategy
        
        def authenticate!
          super
        end
        
        def return_user
          if self.authenticated?
            r =  Resident.find_by_netid(@netid) 
            !r.nil? ? success!(r) : fail( "We could not find your user  #{r.inspect} in the database")
          else
            self.login!
          end
        end
    end
  
  end #end module
end


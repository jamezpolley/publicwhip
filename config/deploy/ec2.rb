set :branch, :master
set :deploy_to, "/srv/www/production"

role :app, %w{deploy@ec2.theyvoteforyou.org.au}
role :web, %w{deploy@ec2.theyvoteforyou.org.au}
role :db,  %w{deploy@ec2.theyvoteforyou.org.au}
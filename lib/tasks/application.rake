namespace :application do
  namespace :cache do
    desc 'Update all the caches'
    task :all => [:member_distances, :whip, :member, :division] do
    end

    desc 'Rebuilds the whole cache of agreement between members'
    task :member_distances => :environment do
      MemberDistance.update_all!
    end

    desc 'Update cache of guessed whips'
    task :whip => :environment do
      puts "Updating cache of guessed whips..."
      Whip.update_all!
    end

    desc "Update cache of member attendance, rebellions, etc"
    task :member => :whip do
      puts "Updating member cache..."
      MemberInfo.update_all!
    end

    desc "Update cache of division attendance, rebellions, etc"
    task :division => :whip do
      puts "Updating division cache..."
      DivisionInfo.update_all!
    end
  end

  namespace :load do
    desc 'Reloads members, offices and electorates from XML files'
    task :members => [:environment, :set_logger_to_stdout] do
      DataLoader::Electorates.load!
      DataLoader::Offices.load!
      DataLoader::Members.load!
    end

    desc 'Load divisions from XML for a specified date'
    task :divisions, [:from_date, :to_date] => [:environment, :set_logger_to_stdout] do |t, args|
      if args[:to_date]
        DataLoader::Debates.load!(Date.parse(args[:from_date]), Date.parse(args[:to_date]))
      else
        DataLoader::Debates.load!(Date.parse(args[:from_date]))
      end
    end
  end

  namespace :seed do
    desc ' WARNING deletes data: Create db/seed.rb sample data to make the life of the developer a joyous one'
    task :create => :environment do
      FileUtils.rm_rf("db/seeds.rb")
      Rake::Task["db:reset"].invoke
      Rake::Task["application:load:members"].invoke
      # Just load divisions from 13 Feb 2014
      Rake::Task["application:load:divisions"].invoke("2014-02-13")
      # Let's prune the members down to two in each house
      puts "Pruning (or should I say culling?) members..."
      members = Member.in_australian_house("senate").current_on(Date.today).limit(2) +
        Member.in_australian_house("representatives").current_on(Date.today).limit(2)
      Member.find_each {|member| member.destroy unless members.include?(member)}
      Rake::Task["application:cache:all"].invoke
      # TODO This doesn't yet create a user or any policy information nor edited motion text
      Rake::Task["db:seed:dump"].invoke
    end
  end

  task :set_logger_to_stdout do
    Rails.logger = ActiveSupport::Logger.new(STDOUT)
    Rails.logger.level = 1
  end
end

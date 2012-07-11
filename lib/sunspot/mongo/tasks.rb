namespace :sunspot do
  namespace :mongo do

    # Inspired by the private Rails::Mongoid#determine_model method
    def determine_mongoid_model(path)
      parts = /app\/models\/(.*).rb$/.match(path).captures.first.split('/').map{ |x| x.camelize }
      begin
        return parts.join("::").constantize
      rescue NameError, LoadError
        return parts.last.constantize
      end
    end

    desc "Reindex all models that include Sunspot::Mongo and are located in your application's models directory."
    task :reindex, [:models, :batch_size] => :environment do |t, args|
      batch_size = args[:batch_size] || 1000
      sunspot_models = if args[:models]
         args[:models].split('+').map{|m| m.constantize}
      else
        all_files = Dir.glob(Rails.root.join('app', 'models', '**', '*.rb'))
        all_models = all_files.map { |path| determine_mongoid_model(path) }
        all_models.select { |m| m.include?(Sunspot::Mongo) and m.searchable? }
      end

      sunspot_models.each do |model|
        puts "reindexing #{model}"
        (model.count / Float(batch_size)).ceil.times do |i|
          model.all.order_by([['_id', Mongo::ASCENDING]])
                   .skip(i * batch_size)
                   .limit(batch_size).each do |instance|
            instance.index
          end
        end
      end
      Sunspot.commit
    end
  end
end

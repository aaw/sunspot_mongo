namespace :sunspot do
  namespace :mongo do
    desc "Reindex all models that include Sunspot::Mongo and are located in your application's models directory."
    task :reindex, [:models, :batch_size] => :environment do |t, args|
      args[:batch_size] = 1000 unless args[:batch_size]
      sunspot_models = if args[:models]
         args[:models].split('+').map{|m| m.constantize}
      else
        all_files = Dir.glob(Rails.root.join('app', 'models', '**', '*.rb'))
        all_models = all_files.map { |path| File.basename(path, '.rb').camelize.constantize }
        all_models.select { |m| m.include?(Sunspot::Mongo) and m.searchable? }
      end

      sunspot_models.each do |model|
        puts "reindexing #{model}"
        (model.count / Float(args[:batch_size])).ceil.times do |i|
          model.all.order_by([['_id', Mongo::ASCENDING]])
                   .skip(i * args[:batch_size])
                   .limit(args[:batch_size]).each do |instance|
            instance.index
          end
        end
      end
      Sunspot.commit
    end
  end
end

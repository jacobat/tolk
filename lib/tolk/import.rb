module Tolk
  module Import
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def import_secondary_locales
        locale_names = Dir.entries(self.locales_config_path)
        locale_names = locale_names.reject {|l| ['.', '..'].include?(l) || !l.ends_with?('.yml') }.map {|x| x.split('.').first } - [Tolk::Locale.primary_locale.name]

        locale_names.each {|l| import_locale(l) }
      end

      def import_locale(locale_name)
        locale = Tolk::Locale.find_or_create_by_name(locale_name)
        data = locale.read_locale_files_without_defaults

        phrases = Tolk::Phrase.all
        count = 0

        data.each do |key, value|
          phrase = phrases.detect {|p| p.key == key}

          if phrase
            translation = locale.translations.new(:text => value, :phrase => phrase)
            count = count + 1 if translation.save
          else
            puts "[ERROR] Key '#{key}' was found in #{locale_name}.yml but #{Tolk::Locale.primary_language_name} translation is missing"
          end
        end

        puts "[INFO] Imported #{count} keys from #{locale_name}.yml"
      end

      def rails_default_translations_regex
        Regexp.new("^(#{rails_default_translations.join('|')})")
      end

      def rails_default_translations
        %w(
          activemodel.errors.template
          activerecord.errors
          date
          datetime
          errors
          helpers
          number
          resource
          support
          time
        )
      end
    end

    def read_locale_files_without_defaults
      self.read_locale_files.reject{|k,v| k.match(self.class.rails_default_translations_regex) }
    end

    def read_locale_files
      Dir["#{self.locales_config_path}/**/*.yml"].inject({}) { |all_translations, file|
        file_translations = self.class.flat_hash(YAML::load_file(file).fetch(self.name, {}))
        all_translations.merge(file_translations)
      }
    end
  end
end

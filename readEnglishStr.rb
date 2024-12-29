require 'json'
file = "BabyKeyboardLock/Localizable.xcstrings"

en_strings = []
JSON.parse(File.read(file)).fetch("strings").each do |key, localizations|
  localizations = localizations["localizations"]
  en_strings << localizations.dig("en", "stringUnit","value")
end


p en_strings

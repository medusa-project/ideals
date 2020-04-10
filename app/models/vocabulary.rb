##
# Controlled vocabulary backed by {Vocabulary#TERMS_PATHNAME}. Obtain instances
# from {with_key}.
#
class Vocabulary

  ##
  # Contains constants for all available vocabulary keys, which correspond to
  # the keys in {TERMS_PATHNAME}.
  #
  class Key
    COMMON_GENRES         = :common_genres
    COMMON_ISO_LANGUAGES  = :common_iso_languages
    COMMON_TYPES          = :common_types
    DEGREE_NAMES          = :degree_names
    DISSERTATION_THESIS   = :dissertation_thesis
  end

  TERMS_PATHNAME = File.join(Rails.root, "config", "vocabulary_terms.yml")

  ##
  # Cache of instances created by {with_key}. Not for public use.
  #
  VOCABULARIES = {}

  attr_reader :key

  ##
  # @return [Enumerable<Vocabulary>]
  #
  def self.all
    Key.constants.map{ |k| with_key(Key.const_get(k)) }
  end

  ##
  # @param key [String,Symbol]
  # @return [Vocabulary]
  #
  def self.with_key(key)
    key = key.to_sym
    VOCABULARIES[key] = Vocabulary.new(key) unless VOCABULARIES.has_key?(key)
    VOCABULARIES[key]
  end

  ##
  # @return [String]
  #
  def name
    @vocab_file[@key]['name']
  end

  ##
  # @return [Enumerable<VocabularyTerm>]
  #
  def terms
    unless @terms
      @terms = @vocab_file[@key]['terms'].map do |term|
        VocabularyTerm.new(term['stored_value'], term['displayed_value'])
      end
    end
    @terms
  end

  private

  ##
  # @param key [String,Symbol]
  # @raises [ArgumentError] if there is no vocabulary with the given key.
  #
  def initialize(key)
    @key        = key.to_s
    @terms      = nil
    @vocab_file = YAML::load_file(TERMS_PATHNAME)
    unless @vocab_file.has_key?(@key)
      raise ArgumentError, "Invalid vocabulary key"
    end
  end

end

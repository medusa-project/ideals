# frozen_string_literal: true

require Rails.root.join("lib/seed_data/template_registered_elements")

puts "Seeding bootstrap data..."

SeedData::TemplateRegisteredElements.call

puts "Done."
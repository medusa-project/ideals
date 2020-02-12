# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Role.create!(name: "sysadmin")

elements = {
    title: RegisteredElement.create!(name: "title",
                                     uri: "http://example.org/title"),
    description: RegisteredElement.create!(name: "description",
                                           uri: "http://example.org/description"),
    subject: RegisteredElement.create!(name: "subject",
                                       uri: "http://example.org/subject")
}

profile = MetadataProfile.create!(name: "Default Profile", default: true)
profile.elements.build(registered_element: elements[:title],
                       label: "Title",
                       index: 0,
                       visible: true,
                       facetable: false,
                       searchable: true,
                       sortable: false,
                       repeatable: false,
                       required: true)
profile.elements.build(registered_element: elements[:description],
                       label: "Description",
                       index: 1,
                       visible: true,
                       facetable: false,
                       searchable: true,
                       sortable: false,
                       repeatable: true,
                       required: false)
profile.elements.build(registered_element: elements[:subject],
                       label: "Subject",
                       index: 2,
                       visible: true,
                       facetable: true,
                       searchable: true,
                       sortable: false,
                       repeatable: true,
                       required: false)

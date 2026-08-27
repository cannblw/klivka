class DemoPersonaSeedData
  PERSONAS = [
    {
      name: "Anna Roberts",
      birthday: "1998-04-17",
      first_met: { date: "2020-09-14", note: "We met in Mechanical Engineering lab during our first week at university. Anna had already labeled every cable in the room and still stayed late to help me debug a motor controller." },
      notes: [
        "Mechanical engineer at a wind-turbine company in Gothenburg. She moved to Sweden four years ago because she has always preferred cold mornings to Florida's heat.",
        "Married to Elise for two years. Anna is a careful planner, a terrible liar at surprise parties, and the person to call when a household appliance makes a worrying noise.",
        "She is learning laminated pastry and keeps a notebook of croissant experiments. She dislikes grapes, loves red kitchenware, and has been saving for a serious stand mixer.",
        "Anna's ideal Saturday is a long walk in cold weather followed by a bakery stop. She always brings home one recipe to improve."
      ],
      phone: { number: "000 000 0142", label: "Mobile" },
      email: { email: "anna.roberts@example.com", label: "Personal" },
      dates: [ { label: "Wedding anniversary", date: "2024-06-22" } ],
      gift_list: { title: "Anna's baking shelf", items: [ "Stainless-steel dough scraper", "Red digital kitchen scale", "Baking steel for the oven" ] },
      interactions: [
        { date: "2026-07-18", method: "video", note: "Anna showed me the first croissant batch that actually had distinct layers." },
        { date: "2026-05-09", method: "message", note: "Sent photos from her windy weekend on the Bohuslän coast." }
      ],
      cadence: "monthly"
    },
    {
      name: "Marcus Chen",
      birthday: "1992-11-03",
      first_met: { date: "2018-02-10", note: "We met at a neighborhood planning workshop. Marcus challenged the proposed car park, then drew a better public square on the back of the agenda." },
      notes: [
        "Urban planner focused on walkable neighborhoods and safer school streets. He works for the city and knows the bus network better than the official app.",
        "Lives with his partner Theo and their elderly rescue greyhound, Mina. Marcus cooks one enormous meal every Sunday and labels every container with the date."
      ],
      phone: { number: "000 000 0188", label: "Mobile" },
      email: { email: "marcus.chen@example.com", label: "Work" },
      dates: [ { label: "Move-in anniversary", date: "2021-09-01" } ],
      gift_list: { title: "Things for Marcus", items: [ "Framed vintage bus map", "Good table-tennis rubbers", "Ceramic rice cooker measuring cup" ] },
      interactions: [
        { date: "2026-08-01", method: "in_person", note: "Walked the new school-street pilot and stopped for dumplings." },
        { date: "2026-06-14", method: "call", note: "He called after Mina's vet appointment. Mina is doing well." }
      ],
      interaction_history: {
        count: 20,
        start_date: "2025-12-20",
        methods: %w[message call in_person],
        notes: [
          "Shared a new transit map and asked for my opinion.",
          "Sent a photo from Mina's walk.",
          "Talked through the latest neighborhood planning meeting.",
          "Compared notes on a restaurant near the new tram stop."
        ]
      },
      cadence: "quarterly"
    },
    {
      name: "Sofía Álvarez",
      birthday: "1995-01-29",
      first_met: { date: "2019-05-26", note: "Sofia volunteered at the community health fair where I was helping with registration. She remembered every child's name by the end of the afternoon." },
      notes: [
        "Pediatric nurse at a public hospital. She is calm in emergencies, keeps cartoon stickers in every pocket, and has a gift for explaining frightening things plainly.",
        "She grew up between Valencia and Bogotá and still spends Sunday mornings making arepas with her mother over video call.",
        "Sofía loves swimming before work, collects tiny illustrated cookbooks, and is trying to convince her building to start a shared herb garden."
      ],
      phone: { number: "000 000 0031", label: "Mobile" },
      email: { email: "sofia.alvarez@example.com", label: "Personal" },
      dates: [ { label: "Mother's birthday", date: "1963-10-08" } ],
      gift_list: { title: "Sofia's little comforts", items: [ "Waterproof swim bag", "Illustrated cookbook from Bogotá", "Window-box herb markers" ] },
      interactions: [
        { date: "2026-07-27", method: "message", note: "She sent a picture of the basil finally surviving the heat." },
        { date: "2026-04-19", method: "in_person", note: "Coffee after her Sunday swim. She was planning a trip to Bogotá." }
      ],
      interaction_history: {
        count: 28,
        start_date: "2025-12-15",
        methods: %w[message call video in_person],
        notes: [
          "Checked in after a long hospital shift.",
          "Shared a new recipe and asked whether I had tried it.",
          "Talked about the herb garden and her mother's latest advice.",
          "Sent a picture from an early morning swim."
        ]
      },
      cadence: "monthly"
    },
    {
      name: "Idris Okafor",
      birthday: "1989-08-12",
      first_met: { date: "2017-11-04", note: "We met when Idris photographed the opening of the community cinema. He lent me a spare battery and stayed afterward to talk about documentary ethics." },
      notes: [
        "Documentary photographer whose current project follows independent cinemas and the people keeping them open. He is patient, observant, and always carries a notebook.",
        "Idris was born in Lagos and now lives in Bristol with his husband Daniel. Their flat has more plants than chairs and a permanent smell of darkroom chemicals."
      ],
      phone: { number: "000 000 0416", label: "Mobile" },
      email: { email: "idris.okafor@example.com", label: "Work" },
      dates: [ { label: "Photography project launch", date: "2025-11-04" } ],
      gift_list: { title: "For Idris's darkroom", items: [ "Archival negative sleeves", "Brass lens brush", "A small thermos that will not leak" ] },
      interactions: [
        { date: "2026-07-05", method: "call", note: "He called from a cinema in Leeds between screenings." },
        { date: "2026-03-21", method: "message", note: "Shared a beautiful contact sheet from his latest interview." }
      ],
      cadence: "quarterly"
    },
    {
      name: "Claire Dubois",
      birthday: "1997-02-14",
      first_met: { date: "2021-01-18", note: "Claire was the pastry chef at the tiny café near my old office. We became people after she rescued my disastrous birthday tart with a very stern lesson about butter temperature." },
      notes: [
        "Pastry chef and owner of a six-seat bakery in Lyon. She starts work before sunrise and insists that every recipe should include a note about the weather.",
        "Claire is engaged to Mathieu, a bicycle frame builder. They are renovating a yellow townhouse one room at a time and disagree about whether the kitchen needs green or blue tiles.",
        "She loves antique cookbooks, black coffee, and long train trips. She cannot stand artificial vanilla and keeps a running list of the best bakeries near every station.",
        "Claire's bakery closes on Mondays. She uses that day to test fillings, visit her grandmother, and refuse to answer work emails."
      ],
      phone: { number: "000 000 4218", label: "Mobile" },
      email: { email: "claire.dubois@example.com", label: "Personal" },
      dates: [ { label: "Engagement anniversary", date: "2025-07-09" } ],
      gift_list: { title: "Claire's bakery wishlist", items: [ "Antique French pastry book", "Blue-and-white cake stand", "Small offset spatula" ] },
      interactions: [
        { date: "2026-07-09", method: "in_person", note: "Stopped by the bakery for her engagement anniversary. She sent me home with madeleines." },
        { date: "2026-02-14", method: "message", note: "Her bakery sold out before noon. She sounded exhausted and delighted." }
      ],
      interaction_history: {
        count: 24,
        start_date: "2025-12-01",
        methods: %w[message call in_person],
        notes: [
          "Asked for feedback on a new tart.",
          "Sent a photo of the morning bake.",
          "Talked about the townhouse renovation.",
          "Shared a train route for the next weekend trip."
        ]
      },
      cadence: "monthly"
    },
    {
      name: "Jonas Berg",
      birthday: "1990-06-30",
      first_met: { date: "2016-10-22", note: "We met at an accessibility hackathon. Jonas fixed the keyboard navigation in my prototype, then explained every change without making me feel foolish." },
      notes: [
        "Accessibility researcher who tests software with screen readers and switch controls. He cares about the small details that decide whether a product feels welcoming.",
        "Jonas lives in Malmö with his wife Liv and their twins, who are currently obsessed with dinosaurs and making up new rules for board games."
      ],
      phone: { number: "000 000 0274", label: "Mobile" },
      email: { email: "jonas.berg@example.com", label: "Work" },
      dates: [ { label: "Twins' birthday", date: "2020-03-11" } ],
      gift_list: { title: "Jonas's workshop", items: [ "Low-profile keycap set", "Cardamom tea", "Dinosaur puzzle for the twins" ] },
      interactions: [
        { date: "2026-07-30", method: "video", note: "He gave me a tour of the keyboard repair bench while the twins argued in the background." },
        { date: "2026-05-02", method: "message", note: "Sent a link to an excellent accessibility conference talk." }
      ],
      cadence: "quarterly"
    },
    {
      name: "Priya Nair",
      birthday: "1993-09-21",
      first_met: { date: "2018-06-02", note: "We met at a climate data workshop. Priya turned a room full of confusing charts into one clear question everyone could answer." },
      notes: [
        "Climate data scientist studying urban heat islands. She works remotely from Bengaluru and spends too much time explaining why one unusually cool day does not disprove climate change.",
        "Priya is close to her younger brother Arjun and sends him a voice note every Friday. She is engaged to Meera, and they are planning a small wedding near the coast.",
        "She loves classical dance, mango pickle, and brightly patterned notebooks. Her current hobby is growing balcony tomatoes with mixed success.",
        "Priya keeps a list of every place she wants to take Meera after the wedding. The list currently includes a monsoon train ride and three different dosa restaurants.",
        "When she is stressed, she reorganizes her data visualizations by color. It does not solve the problem, but it makes her feel briefly in control."
      ],
      phone: { number: "000 000 0142", label: "Mobile" },
      email: { email: "priya.nair@example.com", label: "Personal" },
      dates: [ { label: "Wedding date", date: "2026-12-12" } ],
      gift_list: { title: "Priya's balcony garden", items: [ "Terracotta self-watering pot", "Heat-resistant gardening gloves", "A notebook with graph paper" ] },
      interactions: [
        { date: "2026-08-08", method: "video", note: "Priya showed me the tomato plants and the spreadsheet tracking each leaf." },
        { date: "2026-06-20", method: "message", note: "She sent three possible wedding invitations and asked for a vote." }
      ],
      cadence: "monthly"
    },
    {
      name: "Mateo Silva",
      birthday: "1986-12-05",
      first_met: { date: "2015-09-08", note: "Mateo taught the evening music class at the community center. He let me borrow his spare guitar for a month and never once asked why I kept playing the same three chords." },
      notes: [
        "High-school music teacher in Porto. He believes every student should have one song they can play confidently, even if they never perform for anyone else.",
        "Mateo co-parents his daughter Inês and takes her to the Saturday market for pastries. He is dating Rui, who pretends not to like Mateo's enormous vinyl collection.",
        "He plays classical guitar, makes excellent caldo verde, and has recently become fascinated by field recordings of old train stations."
      ],
      phone: { number: "000 000 5683", label: "Mobile" },
      email: { email: "mateo.silva@example.com", label: "Personal" },
      dates: [ { label: "First school concert", date: "2024-12-14" } ],
      gift_list: { title: "Mateo's music room", items: [ "Nylon guitar strings", "Record-cleaning brush", "Small metronome" ] },
      interactions: [
        { date: "2026-07-12", method: "in_person", note: "Listened to his students' end-of-term concert. Inês played the opening song." },
        { date: "2026-04-04", method: "call", note: "He called from the market to ask whether custard tarts count as breakfast." }
      ],
      cadence: "quarterly"
    },
    {
      name: "Elżbieta Wójcik",
      birthday: "1984-03-08",
      first_met: { date: "2014-04-26", note: "Elżbieta and I met while volunteering at a local museum. She could identify the age of a wooden frame by smell, which I still think is a superpower." },
      notes: [
        "Museum conservator specializing in paintings and paper. Elżbieta spends her days making careful repairs that should be invisible, then gets excited about a two-hundred-year-old pencil mark.",
        "She grew up in Gdańsk and now lives in Kraków with her wife Nora and a very opinionated cat named Goethe. Their apartment is full of linen, plants, and books stacked in unstable towers.",
        "Elżbieta enjoys lake swimming, watercolor postcards, and fixing fountain pens. She dislikes loud restaurants and will always choose a train over a plane when possible."
      ],
      phone: { number: "000 000 2086", label: "Mobile" },
      email: { email: "elzbieta.wojcik@example.com", label: "Work" },
      dates: [ { label: "Wedding anniversary", date: "2019-08-31" } ],
      gift_list: { title: "Elżbieta's careful things", items: [ "Archival watercolor paper", "Replacement nib for a fountain pen", "Soft linen swimming towel" ] },
      interactions: [
        { date: "2026-07-23", method: "message", note: "She sent a photo of Goethe sitting inside an empty archival box." },
        { date: "2026-05-16", method: "in_person", note: "Visited the museum exhibit Hannah helped restore." }
      ],
      cadence: "quarterly"
    },
    {
      name: "Leila Haddad",
      birthday: "1991-07-19",
      first_met: { date: "2019-03-17", note: "We met planting trees at the neighborhood allotment. Leila arrived with labeled seedlings, a thermos of mint tea, and a plan for making the whole block greener." },
      notes: [
        "Community garden coordinator in Marseille. She helps apartment buildings grow food in tiny spaces and knows exactly which plants survive a neglected balcony.",
        "Leila is engaged to Samir, an elementary-school teacher. Their wedding will be small, sunny, and apparently full of homemade pickles.",
        "She loves swimming in the sea before breakfast, old detective novels, and bright yellow ceramics. She is allergic to kiwi but keeps forgetting to tell new restaurants."
      ],
      phone: { number: "000 000 1964", label: "Mobile" },
      email: { email: "leila.haddad@example.com", label: "Personal" },
      dates: [ { label: "Garden opening day", date: "2022-05-14" }, { label: "Wedding anniversary", date: "2026-09-19" } ],
      gift_list: { title: "For Leila's garden", items: [ "Yellow ceramic plant labels", "Compact pruning shears", "A waterproof picnic blanket" ] },
      interactions: [
        { date: "2026-08-02", method: "in_person", note: "Helped paint the garden gate. Leila brought mint tea and a basket of tomatoes." },
        { date: "2026-06-07", method: "message", note: "She sent the first draft of the wedding menu." }
      ],
      cadence: "monthly"
    },
    {
      name: "Tomás Hernández",
      birthday: "1996-10-27",
      first_met: { date: "2020-02-01", note: "Tomás repaired my bicycle after I bent the wheel on a pothole. He explained the repair, charged me less than expected, and remembered my tire pressure forever afterward." },
      notes: [
        "Bicycle mechanic and co-owner of a repair shop in Mexico City. He can diagnose a clicking chain by ear and believes every bike deserves a second chance.",
        "Tomás shares a house with two people and a dog called Nube. He is dating Valeria, who is the only person allowed to reorganize his tool wall.",
        "He rides at dawn, collects enamel cycling pins, and is learning to cook dishes that do not begin with instant noodles."
      ],
      phone: { number: "000 000 1462", label: "Work" },
      email: { email: "tomas.hernandez@example.com", label: "Work" },
      dates: [ { label: "Shop anniversary", date: "2023-02-01" } ],
      gift_list: { title: "Tomás's tool wall", items: [ "Bright orange tire levers", "Magnetic parts tray", "Enamel mountain-bike pin" ] },
      interactions: [
        { date: "2026-07-26", method: "in_person", note: "Dropped off my bike for its annual tune-up and stayed for coffee." },
        { date: "2026-05-24", method: "message", note: "He sent a picture of Nube asleep in a basket of inner tubes." }
      ],
      cadence: "quarterly"
    },
    {
      name: "Nora Petrov",
      birthday: "1988-05-06",
      first_met: { date: "2013-07-13", note: "Nora was giving a talk about tide pools at the science museum. We started talking afterward and missed the last bus because neither of us wanted to stop discussing octopuses." },
      notes: [
        "Marine biologist studying kelp forests on the Adriatic coast. Nora spends part of the year at sea and the rest trying to convince people that conservation is not just a summer hobby.",
        "She grew up in Split and now lives in Trieste with her partner Luca. Their kitchen is decorated with shells, maps, and a strict no-plastic rule.",
        "Nora loves underwater sketching, strong espresso, and repairing old diving watches. She is afraid of pigeons but completely unafraid of sharks."
      ],
      phone: { number: "000 000 7190", label: "Mobile" },
      email: { email: "nora.petrov@example.com", label: "Work" },
      dates: [ { label: "Kelp survey season", date: "2025-06-15" } ],
      gift_list: { title: "Nora's next expedition", items: [ "Waterproof field notebook", "Replacement dive-watch strap", "Blue graphite pencils" ] },
      interactions: [
        { date: "2026-07-02", method: "video", note: "Nora called from the research vessel and introduced me to the crew's smallest octopus fan." },
        { date: "2026-03-08", method: "message", note: "Shared a sketch of a kelp forest made during a storm delay." }
      ],
      cadence: "quarterly"
    },
    {
      name: "Elliot Brooks",
      birthday: "1994-01-11",
      first_met: { date: "2018-10-06", note: "Elliot was selling small blue bowls at the autumn craft market. I bought one, chipped it the same week, and brought it back so he could show me how to repair it." },
      notes: [
        "Ceramic artist working from a shared studio in Bristol. Elliot makes practical tableware with uneven edges because he likes evidence that a human made it.",
        "He lives above the studio with his boyperson Kieran and a retired racing greyhound named Fig. Fig is terrified of the pottery wheel.",
        "Elliot loves folk music, spicy noodles, and second-hand furniture. He is trying to keep one houseplant alive and refuses to admit the fern is already dead."
      ],
      phone: { number: "000 000 0583", label: "Mobile" },
      email: { email: "elliot.brooks@example.com", label: "Personal" },
      dates: [ { label: "Studio opening", date: "2022-10-06" } ],
      gift_list: { title: "Elliot's studio", items: [ "Cobalt underglaze", "Apron with deep pockets", "A sturdy wooden trimming tool" ] },
      interactions: [
        { date: "2026-07-15", method: "in_person", note: "Visited the studio sale. Elliot gave me the bowl with the crooked handle." },
        { date: "2026-04-11", method: "call", note: "He called to celebrate finally selling out a whole shelf of mugs." }
      ],
      cadence: "monthly"
    },
    {
      name: "Maya Thompson",
      birthday: "1987-09-02",
      first_met: { date: "2012-05-19", note: "Maya and I worked at the same legal-aid clinic. She stayed late to help a tenant write a letter, then stayed later to make sure the tenant had a safe way home." },
      notes: [
        "Public defender in Chicago. Maya is direct, funny, and exceptionally good at turning a complicated legal process into three clear next steps.",
        "She is married to Jordan and has twin sons who are both convinced they will become professional basketball players. Her parents live nearby and have a standing Sunday dinner invitation."
      ],
      phone: { number: "000 000 0149", label: "Mobile" },
      email: { email: "maya.thompson@example.com", label: "Personal" },
      dates: [ { label: "Wedding anniversary", date: "2016-08-20" } ],
      gift_list: { title: "Maya's quiet evenings", items: [ "Small jazz-club gift card", "Lemon pie baking weights", "Soft reading lamp" ] },
      interactions: [
        { date: "2026-07-31", method: "call", note: "A rare long call after the boys went to camp. She sounded more rested." },
        { date: "2026-05-10", method: "in_person", note: "Met for lemon pie before her favorite trio played downtown." }
      ],
      cadence: "quarterly"
    },
    {
      name: "Łukasz Zieliński",
      birthday: "1993-12-18",
      first_met: { date: "2017-03-25", note: "Łukasz joined our small game-jam team with a notebook full of tiny character sketches. We made a terrible game and laughed for twelve hours straight." },
      notes: [
        "Game designer at a small independent studio in Warsaw. Łukasz cares about gentle games, meaningful choices, and making menus that do not punish people for needing larger text.",
        "He lives with his sister Zuzanna and their cat Mochi. Łukasz is dating Haru, who runs a neighborhood bookshop and recommends one novel for every game Łukasz designs.",
        "He collects fountain pens, makes elaborate pierogi lunches, and practices fencing on Wednesday evenings. His favorite color is moss green."
      ],
      phone: { number: "000 000 2176", label: "Mobile" },
      email: { email: "lukasz.zielinski@example.com", label: "Work" },
      dates: [ { label: "First game release", date: "2024-03-25" } ],
      gift_list: { title: "Łukasz's desk", items: [ "Moss-green notebook", "Fine-tip refill for his favorite pen", "Tiny cat-shaped cable clips" ] },
      interactions: [
        { date: "2026-07-20", method: "video", note: "Kenji showed me the new game prototype and Mochi walked across the keyboard." },
        { date: "2026-04-25", method: "message", note: "He sent a photo of an exceptionally neat bento lunch." }
      ],
      cadence: "quarterly"
    }
  ].freeze

  PERSON_COUNT = PERSONAS.length

  def self.call(user:)
    new(user:).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    Person.transaction do
      @user.people.destroy_all
      PERSONAS.each { |persona| seed_persona(persona) }
    end
  end

  private

  attr_reader :user

  def seed_persona(persona)
    person = user.people.create!(name: persona.fetch(:name))
    create_entry(person, "Entry::Birthday", entry_date: date(persona.fetch(:birthday)))
    create_entry(person, "Entry::FirstMet", entry_date: date(persona.dig(:first_met, :date)), content: {
      "note" => persona.dig(:first_met, :note), "date_precision" => "day"
    })
    persona.fetch(:notes).each { |text| create_entry(person, "Entry::Note", content: { "text" => text }) }
    create_contact_entry(person, "Entry::Phone", persona[:phone]) if persona[:phone]
    create_contact_entry(person, "Entry::Email", persona[:email]) if persona[:email]
    persona.fetch(:dates, []).each do |date_entry|
      create_entry(person, "Entry::Date", entry_date: date(date_entry.fetch(:date)), content: { "label" => date_entry.fetch(:label) })
    end
    create_gift_list(person, persona[:gift_list]) if persona[:gift_list]
    persona.fetch(:interactions).each do |interaction|
      person.interactions.create!(
        occurred_on: date(interaction.fetch(:date)),
        contact_method: interaction.fetch(:method),
        note: interaction.fetch(:note)
      )
    end
    seed_interaction_history(person, persona.fetch(:interaction_history, {}))
    person.create_keep_in_touch_setting!(cadence: persona.fetch(:cadence), enabled_on: date("2026-01-01")) if persona[:cadence]
  end

  def create_contact_entry(person, type, attributes)
    create_entry(person, type, content: attributes.transform_keys(&:to_s))
  end

  def create_gift_list(person, gift_list)
    items = gift_list.fetch(:items).each_with_index.map do |text, index|
      { "id" => "demo-gift-#{index + 1}", "text" => text, "checked" => false }
    end
    create_entry(person, "Entry::GiftList", content: { "title" => gift_list.fetch(:title), "items" => items })
  end

  def seed_interaction_history(person, history)
    return if history.blank?

    history.fetch(:count).times do |index|
      person.interactions.create!(
        occurred_on: date(history.fetch(:start_date)) - (index * 14).days,
        contact_method: history.fetch(:methods).fetch(index % history.fetch(:methods).length),
        note: history.fetch(:notes).fetch(index % history.fetch(:notes).length)
      )
    end
  end

  def create_entry(person, type, entry_date: nil, content: {})
    person.entries.create!(type:, entry_date:, content:)
  end

  def date(value)
    Date.iso8601(value)
  end
end

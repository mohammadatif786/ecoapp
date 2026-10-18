class WizardInterest {
  final String label;
  final String icon;

  const WizardInterest(this.label, this.icon);
}

/// Mirrors web `Wizard.vue` lists.
class WizardConstants {
  static const languages = [
    'English',
    'Spanish',
    'French',
    'Haitian Creole',
    'Dutch',
    'Papiamento',
    'Portuguese',
    'Sranan Tongo',
  ];

  static const interests = <WizardInterest>[
    WizardInterest('Music Festivals', '🎵'),
    WizardInterest('Travel', '🛫'),
    WizardInterest('Cooking', '🍳'),
    WizardInterest('Books', '📚'),
    WizardInterest('Yoga', '🧘'),
    WizardInterest('Movies', '🎬'),
    WizardInterest('Wine', '🍷'),
    WizardInterest('Church Events', '⛪'),
    WizardInterest('Liming', '🌴'),
    WizardInterest('Carnival / Mas', '🎭'),
    WizardInterest('Junkanoo', '🐚'),
    WizardInterest('Soca Fêtes', '🎶'),
    WizardInterest('Reggae & Dancehall', '🟩'),
    WizardInterest('Kompa / Zouk', '🇭🇹'),
    WizardInterest('Steel Pan', '🥁'),
    WizardInterest('Boat Fêtes', '🛥️'),
    WizardInterest('Beach Lime / Bonfire', '🏖️'),
    WizardInterest('Food & Rum Festivals', '🍹'),
    WizardInterest('Crop Over', '🎉'),
    WizardInterest('J\'ouvert', '🌅'),
    WizardInterest('Rake & Scrape', '🪘'),
    WizardInterest('Salsa Socials', '🫶'),
    WizardInterest('Bachata Nights', '💜'),
    WizardInterest('Reggaetón Parties', '🔥'),
    WizardInterest('Cumbia & Vallenato', '🥁'),
    WizardInterest('Samba Blocos / Pagode', '🟡'),
    WizardInterest('Forró Nights', '🪗'),
    WizardInterest('Mariachi / Regional Mexicano', '🎺'),
    WizardInterest('Día de los Muertos (festivals)', '💐'),
    WizardInterest('Ferias & Street Fairs', '🎪'),
    WizardInterest('Latin Food Fairs', '🍽️'),
    WizardInterest('Folkloric Dance Shows', '🩰'),
  ];

  static const whyOptions = <Map<String, String>>[
    {'emoji': '🎉', 'title': 'Here to party'},
    {'emoji': '💬', 'title': 'Here to Link Up'},
    {'emoji': '😊', 'title': 'Here to casual chat'},
    {'emoji': '❤️', 'title': 'Looking for something serious'},
    {
      'emoji': '🎫',
      'title': 'Just Here for Events',
      'description':
          "I'm here to browse and buy tickets—not looking to connect right now.",
    },
    {
      'emoji': '❤️',
      'title': 'Here to make friends',
      'description': "I'm here to meet friends from the region.",
    },
  ];

  static const aboutSuggestions = [
    'Passionate about Caribbean culture, live music, and community events.',
    'Love exploring Latin American festivals, cooking classes, and beach gatherings.',
    'Enjoy volunteering at church events, attending concerts, and traveling to new destinations.',
  ];

  static const aboutFromSelections =
      'I love music festivals, dance events, and cultural gatherings.';
}

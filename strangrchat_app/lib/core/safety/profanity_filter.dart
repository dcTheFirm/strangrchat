class ProfanityFilter {
  static final Set<String> _profaneWords = {
    // English bad words & threats
    'abuse', 'ass', 'asshole', 'bastard', 'bitch', 'crap', 'cunt', 'damn', 'dick',
    'fuck', 'fucker', 'kill', 'nigger', 'penis', 'piss', 'porn', 'rape', 'sex',
    'shit', 'slut', 'suicide', 'whore',
    // Hinglish bad words & slangs
    'bhosdike', 'bhenchod', 'banchod', 'chutiya', 'gandu', 'madarchod', 'mc', 'bc',
    'randi', 'harami', 'saala', 'kamine', 'kamina'
  };

  /// Checks if a message contains profanity or prohibited words.
  static bool hasProfanity(String text) {
    final lowerText = text.toLowerCase();
    final words = lowerText.split(RegExp(r'\s+'));
    for (var word in words) {
      // Clean punctuation
      final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
      if (_profaneWords.contains(cleaned)) {
        return true;
      }
    }
    return false;
  }
}

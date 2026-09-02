CHOSUNG = [
    "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ",
    "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
]
JUNGSUNG = [
    "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ",
    "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"
]
JONGSUNG = [
    "", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ",
    "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ",
    "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
]

CHORD_CHO = [
    "R", "R", "S", "E", "E", "F", "A", "Q", "Q",
    "T", "T", "D", "W", "W", "C", "Z", "X", "V", "G"
]
CHORD_JUNG = [
    "K", "O", "I", "IO", "J", "P", "U", "IP", "H", "HK",
    "HO", "HL", "Y", "N", "NJ", "NP", "NL", "B", "M", "ML", "L"
]
CHORD_JONG = [
    "", "R", "", "T", "S", "W", "G", "E", "F", "R", 
    "A", "Q", "T", "X", "V", "G", "A", "Q", "Q", "T",
    "", "D", "W", "C", "Z", "X", "V", "G"
]
CHORD_CONSONANT_ORDER = [
    "R", "S", "E", "F", "A", "Q", "T", "D", "W", "C", "Z", "X", "V", "G", ""
]

def get_chord(chosung, jungsung, jongsung, cho_idx, jung_idx, jong_idx):
    """Returns Chord letters interpreted from hangul info"""
    # as jongsung,
    #     ', / -> ㄲㅆ
    #     ' + TWGQ -> ㄳㄵㄶㅄ
    #     / + RAQTXVG -> ㄺㄻㄼㄽㄾㄿㅀ

    chord_consonant, chord_vowel, chord_special = "", "", ""
    chord_cho, chord_jung, chord_jong = "", "", ""

    # print(chosung, jungsung, jongsung)
    chord_cho = CHORD_CHO[cho_idx]
    if chosung in "ㄲㄸㅃㅆㅉ":
        chord_special += "^"
    chord_jung = CHORD_JUNG[jung_idx]
    chord_jong = CHORD_JONG[jong_idx]

    if jongsung == "":
        pass
    elif jongsung in "ㄲㄳㄵㄶㅄ":
        chord_special += "'"
    elif jongsung in "ㅆㄺㄻㄼㄽㄾㄿㅀ":
        chord_special += "/"
    
    if chord_cho == chord_jong:
        chord_special += ";"
        chord_jong = ""
    elif CHORD_CONSONANT_ORDER.index(chord_cho) > CHORD_CONSONANT_ORDER.index(chord_jong):
        chord_special += ";"
    
    chord_consonant = chord_cho + chord_jong
    chord_vowel = chord_jung
    return chord_consonant + chord_vowel + chord_special


def compose_hangul(cho, jung, jong=None):
    """Composes Hangul letters into a single syllable character."""
    # Unicode base constants
    HANGUL_BASE = 0xAC00
    CHOSEONG_BASE = 0x1100
    JUNGSEONG_BASE = 0x1161
    JONGSEONG_BASE = 0x11A7

    # Choseong (Initial Consonants) mapping
    try:
        cho_idx = CHOSUNG.index(cho)
        jung_idx = JUNGSUNG.index(jung)
        jong_idx = JONGSUNG.index(jong) if jong else 0
    except ValueError:
        return "Invalid Jamo input."

    # Composition formula
    unicode_val = HANGUL_BASE + (cho_idx * 21 * 28) + (jung_idx * 28) + jong_idx
    return chr(unicode_val)


with open('examples/default_hangul.json', 'w+', encoding='utf-8') as f:
    f.write('{\n\t"_": " "')

    for cho_idx in range(19):
        for jung_idx in range(21):
            for jong_idx in range(28):
                chosung = CHOSUNG[cho_idx]
                jungsung = JUNGSUNG[jung_idx]
                jongsung = JONGSUNG[jong_idx]
                hangul = compose_hangul(chosung, jungsung, jongsung)
                chord = get_chord(chosung, jungsung, jongsung, cho_idx, jung_idx, jong_idx)

                print(hangul, chord)
                f.write(f',\n\t"{chord}": "{hangul}"')
                f.write(f',\n\t"{chord}_": "{hangul} "')
                f.write(f',\n\t"{chord}.": "{hangul}."')
                f.write(f',\n\t"{chord},": "{hangul},"')
                f.write(f',\n\t"{chord}._": "{hangul}. "')
                f.write(f',\n\t"{chord},_": "{hangul}, "')
    
    f.write("\n}")
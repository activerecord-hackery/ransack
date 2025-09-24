/* C code produced by gperf version 3.0.4 */
/* Command-line: gperf  */
/* Computed positions: -k'1,3,$' */

#if !((' ' == 32) && ('!' == 33) && ('"' == 34) && ('#' == 35) \
      && ('%' == 37) && ('&' == 38) && ('\'' == 39) && ('(' == 40) \
      && (')' == 41) && ('*' == 42) && ('+' == 43) && (',' == 44) \
      && ('-' == 45) && ('.' == 46) && ('/' == 47) && ('0' == 48) \
      && ('1' == 49) && ('2' == 50) && ('3' == 51) && ('4' == 52) \
      && ('5' == 53) && ('6' == 54) && ('7' == 55) && ('8' == 56) \
      && ('9' == 57) && (':' == 58) && (';' == 59) && ('<' == 60) \
      && ('=' == 61) && ('>' == 62) && ('?' == 63) && ('A' == 65) \
      && ('B' == 66) && ('C' == 67) && ('D' == 68) && ('E' == 69) \
      && ('F' == 70) && ('G' == 71) && ('H' == 72) && ('I' == 73) \
      && ('J' == 74) && ('K' == 75) && ('L' == 76) && ('M' == 77) \
      && ('N' == 78) && ('O' == 79) && ('P' == 80) && ('Q' == 81) \
      && ('R' == 82) && ('S' == 83) && ('T' == 84) && ('U' == 85) \
      && ('V' == 86) && ('W' == 87) && ('X' == 88) && ('Y' == 89) \
      && ('Z' == 90) && ('[' == 91) && ('\\' == 92) && (']' == 93) \
      && ('^' == 94) && ('_' == 95) && ('a' == 97) && ('b' == 98) \
      && ('c' == 99) && ('d' == 100) && ('e' == 101) && ('f' == 102) \
      && ('g' == 103) && ('h' == 104) && ('i' == 105) && ('j' == 106) \
      && ('k' == 107) && ('l' == 108) && ('m' == 109) && ('n' == 110) \
      && ('o' == 111) && ('p' == 112) && ('q' == 113) && ('r' == 114) \
      && ('s' == 115) && ('t' == 116) && ('u' == 117) && ('v' == 118) \
      && ('w' == 119) && ('x' == 120) && ('y' == 121) && ('z' == 122) \
      && ('{' == 123) && ('|' == 124) && ('}' == 125) && ('~' == 126))
/* The character set is not based on ISO-646.  */
error "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gnu-gperf@gnu.org>."
#endif

struct mysql2_mysql_enc_name_to_rb_map { const char *name; const char *rb_name; };
/* maximum key range = 71, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
mysql2_mysql_enc_name_to_rb_hash (str, len)
     register const char *str;
     register unsigned int len;
{
  static const unsigned char asso_values[] =
    {
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 15,  5,
       0, 30,  5, 25, 40, 10, 20, 50, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 40,  5,  0,
      15, 10,  0,  0,  0,  5, 74,  0, 25,  5,
       0,  5, 74, 74, 20,  5,  5,  0, 74, 45,
      74,  0, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74, 74, 74, 74, 74,
      74, 74, 74, 74, 74, 74
    };
  return len + asso_values[(unsigned char)str[2]] + asso_values[(unsigned char)str[0]] + asso_values[(unsigned char)str[len - 1]];
}

#ifdef __GNUC__
__inline
#if defined __GNUC_STDC_INLINE__ || defined __GNUC_GNU_INLINE__
__attribute__ ((__gnu_inline__))
#endif
#endif
const struct mysql2_mysql_enc_name_to_rb_map *
mysql2_mysql_enc_name_to_rb (str, len)
     register const char *str;
     register unsigned int len;
{
  enum
    {
      TOTAL_KEYWORDS = 42,
      MIN_WORD_LENGTH = 3,
      MAX_WORD_LENGTH = 8,
      MIN_HASH_VALUE = 3,
      MAX_HASH_VALUE = 73
    };

  static const struct mysql2_mysql_enc_name_to_rb_map wordlist[] =
    {
      {""}, {""}, {""},
      {"gbk", "GBK"},
      {""},
      {"utf32", "UTF-32"},
      {"gb2312", "GB2312"},
      {"keybcs2", NULL},
      {""},
      {"ucs2", "UTF-16BE"},
      {"koi8u", "KOI8-R"},
      {"binary", "ASCII-8BIT"},
      {"utf8mb4", "UTF-8"},
      {"macroman", "macRoman"},
      {"ujis", "eucJP-ms"},
      {"greek", "ISO-8859-7"},
      {"cp1251", "Windows-1251"},
      {"utf16le", "UTF-16LE"},
      {""},
      {"sjis", "Shift_JIS"},
      {"macce", "macCentEuro"},
      {"cp1257", "Windows-1257"},
      {"eucjpms", "eucJP-ms"},
      {""},
      {"utf8", "UTF-8"},
      {"cp852", "CP852"},
      {"cp1250", "Windows-1250"},
      {"gb18030", "GB18030"},
      {""},
      {"swe7", NULL},
      {"koi8r", "KOI8-R"},
      {"tis620", "TIS-620"},
      {"geostd8", NULL},
      {""},
      {"big5", "Big5"},
      {"euckr", "EUC-KR"},
      {"latin2", "ISO-8859-2"},
      {"utf8mb3", "UTF-8"},
      {""},
      {"dec8", NULL},
      {"cp850", "CP850"},
      {"latin1", "ISO-8859-1"},
      {""},
      {"hp8", NULL},
      {""},
      {"utf16", "UTF-16"},
      {"latin7", "ISO-8859-13"},
      {""}, {""}, {""},
      {"ascii", "US-ASCII"},
      {"cp1256", "Windows-1256"},
      {""}, {""}, {""},
      {"cp932", "Windows-31J"},
      {"hebrew", "ISO-8859-8"},
      {""}, {""}, {""}, {""},
      {"latin5", "ISO-8859-9"},
      {""}, {""}, {""},
      {"cp866", "IBM866"},
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {"armscii8", NULL}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = mysql2_mysql_enc_name_to_rb_hash (str, len);

      if (key <= MAX_HASH_VALUE && key >= 0)
        {
          register const char *s = wordlist[key].name;

          if (*str == *s && !strcmp (str + 1, s + 1))
            return &wordlist[key];
        }
    }
  return 0;
}

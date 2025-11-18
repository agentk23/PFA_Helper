/// Fiscal Terms Glossary
///
/// Provides plain language explanations for all Romanian fiscal terms
/// used in PFA taxation and accounting. Each term includes technical
/// definitions, simple explanations, and practical examples.
///
/// Terms are stored in uppercase keys for case-insensitive lookups.
class FiscalGlossary {
  /// Get explanation for a fiscal term
  ///
  /// Returns the full explanation text for the specified [term],
  /// or null if the term is not found in the glossary.
  /// The lookup is case-insensitive.
  static String? getExplanation(String term) {
    return _glossary[term.toUpperCase()];
  }

  /// Get all terms in alphabetical order
  ///
  /// Returns a sorted list of all fiscal term keys available
  /// in the glossary.
  static List<String> getAllTerms() {
    final terms = _glossary.keys.toList();
    terms.sort();
    return terms;
  }

  /// Search for terms containing the query
  ///
  /// Performs a full-text search across both term names and their
  /// explanations. Returns a map of matching terms and their explanations.
  /// Returns all terms if [query] is empty.
  ///
  /// The search is case-insensitive.
  static Map<String, String> searchTerms(String query) {
    if (query.isEmpty) return _glossary;

    final lowerQuery = query.toLowerCase();
    return Map.fromEntries(
      _glossary.entries.where((entry) =>
          entry.key.toLowerCase().contains(lowerQuery) ||
          entry.value.toLowerCase().contains(lowerQuery)),
    );
  }

  /// Complete glossary of fiscal terms
  static const Map<String, String> _glossary = {
    // P
    'PFA': '''Persoană Fizică Autorizată (Authorized Natural Person)

Ce înseamnă:
Este o formă de organizare pentru desfășurarea unei activități economice de către o persoană fizică, pe cont propriu.

În termeni simpli:
Este ca și cum ai fi patron de firmă, dar fără să înființezi o companie (SRL). Tu personal răspunzi pentru activitate cu propriul tău patrimoni.

Exemplu:
Un programator care lucrează ca freelancer poate fi PFA. Un fotograf independent poate fi PFA.''',

    // C
    'CUI': '''Cod Unic de Identificare (Unique Identification Code)

Ce înseamnă:
Este numărul unic prin care ANAF (fiscul) te identifică ca și contribuabil.

În termeni simpli:
Este ca un CNP (codul numeric personal) al firmei sau PFA-ului tău. Apare pe toate documentele fiscale.

Important:
Pe facturi se scrie RO12345678 (RO + codul tău).''',

    'CIF': '''Cod de Identificare Fiscală (Fiscal Identification Code)

Ce înseamnă:
Același lucru cu CUI - sunt termeni interschimbabili în România.

În termeni simpli:
CIF = CUI. Unii zic CUI, alții zic CIF. Înseamnă același lucru: numărul tău de identificare fiscală.''',

    'CAS': '''Contribuție de Asigurări Sociale (Social Insurance Contribution)

Ce înseamnă:
Este o taxă pe care o plătești pentru pensia ta viitoare.

În termeni simpli:
Din fiecare leu pe care îl câștigi, statul îți pune deoparte bani pentru când te pensionezi. Pentru PFA este 25% din venit, dar numai dacă câștigi peste 48.600 RON pe an (2025).

Exemplu:
Dacă ai venit net de 60.000 RON pe an:
- Plătești minim 12.150 RON pentru CAS
- Acești bani vor conta la pensia ta viitoare

Nu plătești dacă:
- Ești deja pensionar
- Câștigi sub 48.600 RON pe an
- Ești avocat/notar (ai propria casă de pensii)''',

    'CASS': '''Contribuție de Asigurări Sociale de Sănătate (Health Insurance Contribution)

Ce înseamnă:
Este taxa pe care o plătești pentru asigurarea de sănătate.

În termeni simpli:
Cu acești bani, ai dreptul să mergi la doctor gratuit (în sistemul public de sănătate). Pentru PFA este 10% din venit, cu un minim de 2.430 RON pe an (2025).

Exemplu:
Dacă ai venit net de 60.000 RON:
- Plătești 6.000 RON pentru CASS
- Cu asta ai asigurare medicală pentru tot anul

Important:
Spre deosebire de CAS, CASS se plătește ÎNTOTDEAUNA, chiar dacă ai venit mic!

Nu plătești dacă:
- Ai deja asigurare din altă parte (salariu, pensie)
- Ești student, copil, sau asistat social''',

    'CAEN': '''Clasificarea Activităților din Economia Națională (National Economic Activities Classification)

Ce înseamnă:
Este un cod numeric care spune ce fel de activitate desfășori.

În termeni simpli:
Este ca și cum ai pune o etichetă pe afacerea ta: "Programare", "Fotografie", "Consultanță", etc. Fiecare activitate are un cod de 4 cifre.

Exemple:
- 6201 = Programare software
- 6202 = Consultanță IT
- 7420 = Activități fotografice

Important pentru PFA:
- Poți avea maxim 5 coduri CAEN
- Unul trebuie să fie activitate principală
- Unele coduri (6202, 6203) te obligă să fii la sistem real''',

    // I
    'IMPOZIT PE VENIT': '''Income Tax

Ce înseamnă:
Este taxa principală pe care o plătești statului din profitul tău.

În termeni simpli:
Din banii pe care îi câștigi (după ce scazi cheltuielile și contribuțiile CAS/CASS), trebuie să dai 10% statului.

Formula:
1. Venit brut - Cheltuieli = Profit brut
2. Profit brut - CAS - CASS = Venit impozabil
3. Venit impozabil × 10% = Impozit de plată

Exemplu:
- Câștigi 100.000 RON
- Cheltuieli 20.000 RON
- Profit brut: 80.000 RON
- CAS: 20.000 RON
- CASS: 8.000 RON
- Venit impozabil: 52.000 RON
- Impozit: 5.200 RON (10% din 52.000)

IMPORTANT:
Pentru PFA este ÎNTOTDEAUNA 10%, indiferent de domeniul de activitate! Nu există impozit de 3% pentru PFA (doar pentru SRL-uri).''',

    // S
    'SISTEM REAL': '''Real Income System

Ce înseamnă:
Este metoda prin care ți se calculează taxele pe baza veniturilor și cheltuielilor efective.

În termeni simpli:
Ții evidența la fiecare leu câștigat și cheltuit. Taxele se calculează pe diferența dintre venituri și cheltuieli (profitul real).

Avantaje:
- Poți deduce toate cheltuielile pentru activitate
- Mai profitabil dacă ai cheltuieli mari
- Transparent și corect

Dezavantaje:
- Trebuie să ții evidență detaliată
- Registre obligatorii (REF, RJIP, Inventar)
- Mai multă birocrație

Când ești obligat:
- Dacă depășești 25.000 EUR venituri pe an
- Dacă ai CAEN 6202 sau 6203 (consultanță/management IT)
- Dacă alegi voluntar acest sistem''',

    'NORMĂ DE VENIT': '''Presumptive Income System

Ce înseamnă:
Este o metodă simplificată prin care plătești taxe pe o sumă fixă stabilită de stat, nu pe venitul real.

În termeni simpli:
Statul zice: "În domeniul tău, în județul X, norma e 10.000 RON pe an. Dai taxe pe atât, indiferent cât câștigi efectiv."

Avantaje:
- Foarte simplu - nu ții evidență detaliată
- Profitabil dacă câștigi mult peste normă
- Puțină birocrație

Dezavantaje:
- Plătești taxe chiar dacă nu câștigi
- Nu poți deduce cheltuieli
- Riști să plătești mai mult decât ar trebui

Când poți folosi:
- Dacă câștigi sub 25.000 EUR pe an
- Dacă NU ai CAEN 6202 sau 6203
- Dacă alegi acest sistem''',

    // D
    'D212': '''Declarația Unică privind impozitul pe venit și contribuțiile sociale (Single Declaration for Income Tax and Social Contributions)

Ce înseamnă:
Este formularul oficial prin care declari la ANAF ce ai câștigat și ce taxe datorezi.

În termeni simpli:
Este ca o "declarație de venituri" pe care o completezi o dată pe an și o trimiți la fisc. În ea scrii:
- Cât ai câștigat
- Cât ai cheltuit
- Cât datorezi la CAS, CASS, impozit

Când se depune:
Până la 25 MAI în fiecare an, pentru anul precedent.

Exemplu:
În mai 2025 declari veniturile din 2024.

Important:
- Se depune online prin SPV (Spațiul Privat Virtual) ANAF
- Trebuie plătite și taxele până la aceeași dată
- Întârzieri = amenzi (500-1000 RON)''',

    // V
    'VENIT BRUT': '''Gross Income

Ce înseamnă:
Suma totală de bani pe care i-ai încasat de la clienți, înainte să scazi orice.

În termeni simpli:
Tot ce intră în contul/buzunarul tău din activitate, fără excepție.

Exemplu:
Dacă ai facturat 5 clienți:
- Client 1: 10.000 RON
- Client 2: 5.000 RON
- Client 3: 8.000 RON
- Client 4: 12.000 RON
- Client 5: 15.000 RON
Venit brut = 50.000 RON

Important:
Contează doar banii ÎNCASAȚI efectiv, nu facturile emise și neplătite!''',

    'VENIT NET': '''Net Income / Taxable Income

Ce înseamnă:
Profitul tău după ce scazi cheltuielile deductibile din venitul brut.

În termeni simpli:
Banii care rămân după ce scazi ce ai cheltuit pentru activitate.

Formula:
Venit Net = Venit Brut - Cheltuieli Deductibile

Exemplu:
- Venit brut: 100.000 RON
- Cheltuieli (laptop, soft, internet, chirie birou): 30.000 RON
- Venit net = 70.000 RON

Pe acest venit net se calculează CAS, CASS și impozitul.''',

    'CHELTUIELI DEDUCTIBILE': '''Deductible Expenses

Ce înseamnă:
Cheltuielile pe care le poți scădea din venit pentru a reduce taxele.

În termeni simpli:
Banii cheltuiți pentru activitatea ta de care scapi de taxe. Nu plătești taxe pe ei.

Ce poți deduce:
- Materiale și echipamente (laptop, telefon, soft)
- Utilități (curent, internet, telefon)
- Chirie birou/spațiu lucru
- Colaboratori (alți PFA, firme)
- Cursuri profesionale
- Deplasări în interes de serviciu
- CAS și CASS plătite

CE NU poți deduce:
- Mâncare personală
- Haine (dacă nu e echipament de protecție)
- Călătorii personale
- Amenzi

IMPORTANT:
Trebuie să ai FACTURĂ sau BON FISCAL cu CUI-ul tău pe el!''',

    // T
    'TVA': '''Taxa pe Valoarea Adăugată (Value Added Tax - VAT)

Ce înseamnă:
Este o taxă de 19% care se aplică pe majoritatea bunurilor și serviciilor.

În termeni simpli:
Când vinzi ceva, adaugi 19% la preț și dai acei bani statului. Când cumperi ceva, plătești 19% în plus.

Exemplu fără TVA:
- Lucrezi pentru client: 1000 RON
- Încasezi: 1000 RON
- Dai statului din alte taxe

Exemplu CU TVA:
- Lucrezi pentru client: 1000 RON + 190 RON TVA = 1190 RON
- Încasezi: 1190 RON
- Dai statului TVA: 190 RON
- Îți rămân: 1000 RON
- Dar poți scădea TVA-ul de pe cheltuieli!

Când ești obligat să te înregistrezi:
Dacă faci peste 300.000 RON venituri pe an (2025).

Avantaj:
Poți deduce TVA de pe achizițiile tale business.

Dezavantaj:
Facturi mai scumpe pentru clienți, mai multă birocrație.''',

    // A
    'ANAF': '''Agenția Națională de Administrare Fiscală (National Tax Administration Agency)

Ce înseamnă:
Este "fiscul" - instituția statului care colectează taxele și verifică dacă plătești corect.

În termeni simpli:
Este șeful cu taxele în România. Ei stabilesc cât plătești, verifică dacă declari corect, și pot da amenzi dacă greșești.

Ce face ANAF:
- Colectează declarații (D212)
- Încasează taxe (CAS, CASS, impozit, TVA)
- Face controale fiscale
- Gestionează SPV (portal online)
- Aplică amenzi pentru nerespectare

Portal important:
SPV (Spațiul Privat Virtual) - aici depui declarații online.''',

    // R
    'REF': '''Registrul de Evidență Fiscală (Fiscal Evidence Register)

Ce înseamnă:
Este un registru oficial unde notezi toate veniturile și cheltuielile anului.

În termeni simpli:
Este ca un caiet contabil unde scrii:
- Cât ai câștigat în fiecare lună
- Cât ai cheltuit
- Cât datorezi la CAS, CASS, impozit

Format:
Poate fi pe hârtie (vizat de ANAF) sau electronic (Excel, soft contabil).

Obligatoriu pentru:
PFA în sistem real.

Păstrare:
Minim 10 ani!''',

    'RJIP': '''Registrul-Jurnal de Încasări și Plăți (Cash Receipts and Payments Journal)

Ce înseamnă:
Este registrul unde notezi cronologic (zi cu zi) tot ce încasezi și plătești.

În termeni simpli:
Ca un registru de casă unde scrii:
- Data: 15.01.2025
- Document: Factură nr. 5
- Încasare: 5000 RON de la client X

Obligatoriu pentru:
PFA în sistem real.

Ce notezi:
- Data operațiunii
- Număr factură/chitanță
- Suma încasată/plătită
- Soldul final

Important:
Doar banii EFECTIV încasați/plătiți, nu facturile emise!''',

    // S (continued)
    'SPV': '''Spațiul Privat Virtual (Virtual Private Space)

Ce înseamnă:
Este portalul online al ANAF unde îți gestionezi toate treburile fiscale.

În termeni simpli:
Ca un "cont bancar online", dar pentru taxe. Aici:
- Depui declarația D212
- Vezi cât datorezi
- Plătești taxe
- Primești notificări de la ANAF
- Trimiți facturi e-Factura

Link:
https://www.anaf.ro/SpatiulPrivatVirtual/

Acces:
Cu certificat digital sau user/parolă de la ANAF.''',

    'SALARIU MINIM BRUT': '''Minimum Gross Salary

Ce înseamnă:
Este salariul minim pe economie stabilit de guvern în fiecare an.

În termeni simpli:
Este baza de calcul pentru multe praguri fiscale. Pentru 2025 este 4.050 RON.

De ce contează pentru PFA:
- CAS: se calculează în salarii minime (12 sau 24)
- CASS: la fel
- Multe limite și praguri

Exemplu 2025:
- 12 salarii minime = 48.600 RON (prag CAS)
- 24 salarii minime = 97.200 RON (prag CAS maxim)
- 6 salarii minime = 24.300 RON (CASS minim)''',

    // E
    'E-FACTURA': '''Electronic Invoice (RO e-Factura)

Ce înseamnă:
Este sistemul prin care toate facturile trebuie trimise electronic către ANAF.

În termeni simpli:
Emiti o factură în SPV ANAF, ea ajunge automat la ei și la client. Nu mai există "factură pe hârtie" tradițională pentru B2B.

Obligatoriu din:
- 2024: B2B (business to business)
- 1 iulie 2025: și B2C (business to consumer)

Avantaje:
- ANAF știe automat veniturile tale
- Mai puține erori
- Arhivare automată

Important:
Dacă nu trimiți facturile în SPV = AMENDĂ (500 RON)!''',

    // O
    'ONRC': '''Oficiul Național al Registrului Comerțului (National Trade Register Office)

Ce înseamnă:
Este instituția unde te înregistrezi ca PFA.

În termeni simpli:
Când vrei să devii PFA, mergi la ONRC (sau depui online), ei îți dau certificatul de înregistrare și CUI-ul.

Ce fac:
- Înregistrează PFA-uri și firme
- Eliberează certificate
- Gestionează modificări (schimbare CAEN, adresă)
- Radiază PFA-uri (închidere)

Costuri înființare PFA (2025):
Circa 150-300 RON total.''',

    // P (continued)
    'PROFIT': '''Profit / Net Profit

Ce înseamnă:
Diferența dintre cât câștigi și cât cheltuiești.

În termeni simpli:
Banii care rămân în buzunar după ce plătești tot:
- Cheltuieli de activitate
- Taxe (CAS, CASS, impozit)

Formula completă:
1. Venit brut - Cheltuieli = Profit brut
2. Profit brut - CAS - CASS - Impozit = Profit net

Exemplu:
- Venit brut: 100.000 RON
- Cheltuieli: 20.000 RON
- CAS: 20.000 RON
- CASS: 8.000 RON
- Impozit: 5.200 RON
- PROFIT NET = 46.800 RON (asta îți rămâne ție!)''',

    // A (continued)
    'ACTIVITATE PRINCIPALĂ': '''Main Activity

Ce înseamnă:
Dintre cele maxim 5 coduri CAEN pe care le ai, unul trebuie să fie activitatea principală.

În termeni simpli:
Dacă ești și programator, și fotograf, alegi care e activitatea ta PRINCIPALĂ (din care câștigi cel mai mult).

Contează pentru:
- Certificatul de înregistrare
- Norma de venit (dacă o folosești)
- Unele autorizații sectoriale

Cum alegi:
În general, activitatea din care faci cei mai mulți bani.''',

    // F
    'FACTURĂ FISCALĂ': '''Fiscal Invoice

Ce înseamnă:
Este documentul oficial care dovedește o vânzare/prestare de servicii.

În termeni simpli:
Este "chitanța" profesională pe care o dai clientului când lucrezi ceva. Pe ea trebuie să fie:
- Datele tale (PFA, CUI)
- Datele clientului
- Ce ai făcut
- Cât costă
- TVA (dacă ești plătitor)

Numerotare:
Cronologică: FAC001, FAC002, FAC003...

Păstrare:
Minim 10 ani!

Obligatoriu din 2025:
Să fie trimisă și în SPV (e-Factura).''',
  };
}

/// Help topics organized by category
///
/// Provides categorization of fiscal terms for easier navigation
/// in the help system. Each category contains a list of term keys
/// that can be looked up in the FiscalGlossary.
class HelpTopics {
  /// Map of categories to their respective fiscal term keys
  static const Map<String, List<String>> topicsByCategory = {
    'Baze': [
      'PFA',
      'CUI',
      'CIF',
      'CAEN',
      'ONRC',
    ],
    'Taxe și Contribuții': [
      'IMPOZIT PE VENIT',
      'CAS',
      'CASS',
      'TVA',
    ],
    'Sisteme de Impozitare': [
      'SISTEM REAL',
      'NORMĂ DE VENIT',
    ],
    'Venituri și Cheltuieli': [
      'VENIT BRUT',
      'VENIT NET',
      'CHELTUIELI DEDUCTIBILE',
      'PROFIT',
    ],
    'Documente și Registre': [
      'D212',
      'REF',
      'RJIP',
      'FACTURĂ FISCALĂ',
      'E-FACTURA',
    ],
    'Instituții': [
      'ANAF',
      'SPV',
      'ONRC',
    ],
  };

  /// Get all available category names
  ///
  /// Returns a list of all category names in the help system
  static List<String> getCategories() {
    return topicsByCategory.keys.toList();
  }

  /// Get all term keys for a specific category
  ///
  /// Returns a list of term keys that belong to the specified [category].
  /// Returns an empty list if the category doesn't exist.
  static List<String> getTermsForCategory(String category) {
    return topicsByCategory[category] ?? [];
  }
}

/// Quick tips for common scenarios
///
/// Provides quick answers to frequently asked questions about PFA
/// taxation, registration, and compliance in Romania.
class QuickTips {
  /// Map of common questions to their detailed answers
  static const Map<String, String> tips = {
    'Cum calculez impozitul?': '''1. Venit brut - Cheltuieli = Profit brut
2. Profit brut - CAS - CASS = Venit impozabil
3. Venit impozabil × 10% = Impozit de plată

Exemplu simplu:
- Câștigi: 50.000 RON
- Cheltuieli: 10.000 RON
- Profit: 40.000 RON
- CAS: 0 (e sub 48.600)
- CASS: 4.000 RON
- Impozit: (40.000 - 4.000) × 10% = 3.600 RON''',

    'Când plătesc taxele?': '''Deadline UNIC: 25 MAI

Până la 25 mai trebuie:
1. Să depui declarația D212 (online în SPV)
2. Să plătești toate taxele (CAS + CASS + Impozit)

Dacă 25 mai pică sâmbătă/duminică → prima zi lucrătoare.

Întârziere = Amendă 500-1000 RON + dobânzi 0.01%/zi.''',

    'Ce cheltuieli pot deduce?': '''✅ POT deduce:
- Laptop, telefon, echipamente
- Internet, curent, telefon
- Chirie birou
- Software, abonamente
- Cursuri profesionale
- Colaboratori
- Deplasări business
- CAS și CASS

❌ NU POT deduce:
- Mâncare personală
- Haine (dacă nu e echipament)
- Călătorii personale
- Amenzi
- Cheltuieli fără factură/bon cu CUI

IMPORTANT: Trebuie FACTURĂ cu CUI-ul PFA!''',

    'Sistem real sau normă?': '''Alegi SISTEM REAL dacă:
- Ai cheltuieli mari (> 40% din venit)
- Vrei transparență și control
- Faci peste 25.000 EUR pe an (OBLIGATORIU)
- Ai CAEN 6202/6203 (OBLIGATORIU)

Alegi NORMĂ DE VENIT dacă:
- Ai cheltuieli mici
- Vrei simplu, fără evidență
- Faci sub 25.000 EUR pe an
- Nu ai CAEN 6202/6203

În general:
Sistem real = mai profitabil pentru majoritatea!''',

    'Cum știu dacă trebuie TVA?': '''Ești OBLIGAT la TVA dacă:
Faci peste 300.000 RON venituri în ultimele 12 luni.

Poți OPTA pentru TVA oricând (chiar sub 300.000).

Cu TVA:
✅ Deduci TVA de pe achizițiile business
✅ Obligatoriu pentru mulți clienți mari
❌ Prețuri mai mari pentru clienți
❌ Mai multă birocrație (D390 lunar/trimestrial)

Fără TVA:
✅ Mai simplu
✅ Prețuri mai mici pentru clienți
❌ Nu poți deduce TVA''',

    'Ce registre trebuie să țin?': '''Pentru SISTEM REAL (obligatorii):
1. REF (Registrul de Evidență Fiscală)
2. RJIP (Registrul Încasări-Plăți)
3. Registrul Inventar
4. RUC (Registrul Unic de Control)

Pentru NORMĂ DE VENIT (simplificate):
1. REF simplificat
2. RUC

Format:
- Pe hârtie (vizate ANAF) SAU
- Electronic (Excel, soft contabil)

Păstrare: 10 ANI minim!''',

    'Cum mă înregistrez PFA?': '''Pași:
1. Mergi la ONRC sau depui online
2. Completezi cerere + anexă fiscală
3. Alegi CAEN (max 5 coduri)
4. Dovedești sediul (contract chirie/proprietate)
5. Plătești taxa (150-300 RON)
6. Primești certificat + CUI

Acte necesare:
- CI (copie certificată)
- Dovadă sediu
- Dovadă calificare (dacă e cazul)
- Specimen semnătură

Timp: 1-5 zile

După:
- Te înregistrezi în SPV ANAF
- Începi să emiți facturi
- Ții evidență
- Declari anual (D212)''',
  };

  /// Get all available questions
  ///
  /// Returns a list of all questions available in the quick tips system
  static List<String> getAllQuestions() {
    return tips.keys.toList();
  }

  /// Get the answer for a specific question
  ///
  /// Returns the detailed answer for the specified [question],
  /// or null if the question doesn't exist in the tips.
  static String? getAnswer(String question) {
    return tips[question];
  }
}

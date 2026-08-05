// lib/core/data/syllabus_tree.dart
// Complete hierarchical syllabus with Formulas, Definitions & Examples

import '../../models/exam_models.dart';

class SyllabusTree {
  static final Map<SubjectDomain, SyllabusNode> _trees = {};
  static void init() {
    _trees[SubjectDomain.physics] = _buildPhysicsTree();
    _trees[SubjectDomain.chemistry] = _buildChemistryTree();
    _trees[SubjectDomain.mathematics] = _buildMathTree();
    _trees[SubjectDomain.biology] = _buildBiologyTree();
    _trees[SubjectDomain.english] = _buildEnglishTree();
    _trees[SubjectDomain.mat] = _buildMatTree();
    _trees[SubjectDomain.healthKnowledge] = _buildHealthTree();
  }

  static SyllabusNode getTree(SubjectDomain subject) {
    if (_trees.isEmpty) init();
    return _trees[subject] ??
        SyllabusNode(id: "root", nameEn: "Root", subject: "", topic: "");
  }

  static List<SyllabusNode> getAllTopics(SubjectDomain subject) {
    return getTree(subject).flattened.where((n) => n.children.isEmpty).toList();
  }

  static List<SyllabusNode> getWeakTopics(
      SubjectDomain subject, List<String> weakIds) {
    return getAllTopics(subject).where((t) => weakIds.contains(t.id)).toList();
  }

  static SyllabusNode? findTopicById(String topicId) {
    for (final subject in SubjectDomain.values) {
      for (final t in getAllTopics(subject)) {
        if (t.id == topicId) return t;
      }
    }
    return null;
  }

  static List<SyllabusNode> searchTopics(String query) {
    final results = <SyllabusNode>[];
    final lower = query.toLowerCase();
    for (final subject in SubjectDomain.values) {
      for (final topic in getAllTopics(subject)) {
        if (topic.nameEn.toLowerCase().contains(lower) ||
            topic.keywords.any((k) => k.toLowerCase().contains(lower)) ||
            topic.definitions.any((d) => d.toLowerCase().contains(lower))) {
          results.add(topic);
        }
      }
    }
    return results;
  }

  static SyllabusNode _buildPhysicsTree() {
    final root = SyllabusNode(
        id: "PHYS_ROOT", nameEn: "Physics", subject: "Physics", topic: "Root");
    final mechanics = SyllabusNode(
        id: "PHYS_MECH",
        nameEn: "Mechanics",
        subject: "Physics",
        topic: "Mechanics",
        keywords: ["force", "motion", "newton"]);
    mechanics.children.addAll([
      _leaf("PHYS_KIN", "Kinematics", 0.4, [
        "velocity",
        "acceleration",
        "equations of motion"
      ], formulas: [
        "v = u + at",
        "s = ut + 0.5at^2",
        "v^2 = u^2 + 2as",
        "s_n = u + a(n - 0.5)"
      ], definitions: [
        "Kinematics: Study of motion without reference to causes.",
        "Displacement: Shortest distance between initial and final position."
      ], examples: [
        _ex(
            "A car starts from rest, a=2m/s^2, t=10s. Find s.",
            ["s = 0 + 0.5*2*100", "s = 100 m"],
            "100 m",
            "Second equation of motion.")
      ]),
      _leaf("PHYS_NLM", "Newton's Laws of Motion", 0.5, [
        "newton",
        "force",
        "inertia",
        "momentum"
      ], formulas: [
        "F = ma",
        "p = mv",
        "Impulse = F*t = change in momentum"
      ], definitions: [
        "Inertia: Resistance to change in motion.",
        "Momentum: Product of mass and velocity."
      ], examples: [
        _ex("5 kg body, 10 N force. Find a.", ["a = F/m = 10/5"], "2 m/s^2",
            "Newton's Second Law.")
      ]),
      _leaf("PHYS_FRI", "Friction", 0.55, [
        "friction",
        "coefficient",
        "rough"
      ], formulas: [
        "f_s(max) = mu_s * N",
        "f_k = mu_k * N",
        "tan(theta) = mu"
      ], definitions: [
        "Static friction: Self-adjusting, opposes impending motion.",
        "Kinetic friction: Constant, opposes actual motion."
      ]),
      _leaf("PHYS_WEP", "Work, Energy & Power", 0.5, [
        "work",
        "energy",
        "power",
        "kinetic",
        "potential"
      ], formulas: [
        "W = F*s*cos(theta)",
        "KE = 0.5mv^2",
        "PE = mgh",
        "W_net = delta KE",
        "P = W/t = F*v",
        "Spring U = 0.5kx^2"
      ], definitions: [
        "Work: Scalar product of force and displacement.",
        "Kinetic Energy: Energy due to motion.",
        "Potential Energy: Energy due to position."
      ], examples: [
        _ex(
            "Spring k=200 N/m compressed 0.1m. Find U.",
            ["U = 0.5*200*0.01", "U = 1 J"],
            "1 J",
            "Elastic potential energy formula.")
      ]),
      _leaf("PHYS_CIR", "Circular Motion", 0.6,
          ["centripetal", "circular", "radius"],
          formulas: ["a_c = v^2/r = omega^2*r", "F_c = mv^2/r", "v = omega*r"]),
      _leaf("PHYS_ROT", "Rotational Dynamics", 0.7,
          ["torque", "moment of inertia", "angular"],
          formulas: ["tau = I*alpha", "L = I*omega", "KE_rot = 0.5*I*omega^2"]),
      _leaf("PHYS_GRA", "Gravitation", 0.6, [
        "gravity",
        "satellite",
        "escape velocity"
      ], formulas: [
        "F = G*m1*m2/r^2",
        "g = GM/R^2",
        "v_escape = sqrt(2GM/R)",
        "T^2 proportional to r^3"
      ]),
      _leaf(
          "PHYS_ELA", "Elasticity", 0.6, ["young modulus", "stress", "strain"],
          formulas: ["Stress = F/A", "Strain = deltaL/L", "Y = Stress/Strain"]),
      _leaf("PHYS_FLU", "Fluid Mechanics", 0.65, [
        "bernoulli",
        "viscosity",
        "surface tension"
      ], formulas: [
        "P + 0.5*rho*v^2 + rho*gh = const",
        "A1*v1 = A2*v2",
        "F = 6*pi*eta*r*v"
      ]),
    ]);
    for (final c in mechanics.children) {
      c.parent = mechanics;
    }
    root.children.add(mechanics);

    final heat = SyllabusNode(
        id: "PHYS_HEAT",
        nameEn: "Heat & Thermodynamics",
        subject: "Physics",
        topic: "Heat",
        keywords: ["temperature", "heat", "thermodynamics"]);
    heat.children.addAll([
      _leaf("PHYS_TEM", "Temperature & Heat", 0.4,
          ["specific heat", "latent heat", "calorimetry"],
          formulas: ["Q = mc*deltaT", "Q = mL", "Heat lost = Heat gained"]),
      _leaf("PHYS_KTG", "Kinetic Theory of Gases", 0.6,
          ["kinetic theory", "gas laws", "rms velocity"],
          formulas: ["PV = nRT", "v_rms = sqrt(3RT/M)", "KE_avg = 1.5*kT"]),
      _leaf("PHYS_TRH", "Transfer of Heat", 0.5, [
        "conduction",
        "convection",
        "radiation",
        "stefan"
      ], formulas: [
        "Q/t = kA*deltaT/d",
        "P = sigma*A*T^4",
        "lambda_max*T = b"
      ]),
      _leaf("PHYS_LAW", "Laws of Thermodynamics", 0.7,
          ["first law", "second law", "entropy", "carnot", "efficiency"],
          formulas: ["deltaU = Q - W", "eta = 1 - T2/T1", "deltaS >= 0"]),
    ]);
    for (final c in heat.children) {
      c.parent = heat;
    }
    root.children.add(heat);

    final optics = SyllabusNode(
        id: "PHYS_OPT",
        nameEn: "Optics",
        subject: "Physics",
        topic: "Optics",
        keywords: ["light", "lens", "mirror"]);
    optics.children.addAll([
      _leaf("PHYS_REF", "Reflection & Mirrors", 0.45,
          ["mirror", "focal length", "magnification"],
          formulas: ["1/f = 1/u + 1/v", "m = -v/u", "R = 2f"]),
      _leaf("PHYS_RFR", "Refraction & Lenses", 0.55,
          ["lens", "refractive index", "total internal reflection"],
          formulas: ["n = c/v", "1/f = (n-1)(1/R1 - 1/R2)", "sin C = 1/n"]),
      _leaf("PHYS_DIS", "Dispersion", 0.5,
          ["spectrum", "prism", "chromatic aberration"]),
      _leaf("PHYS_INT", "Interference", 0.65,
          ["young double slit", "coherent", "path difference"],
          formulas: ["beta = lambda*D/d", "Path diff = n*lambda (bright)"]),
      _leaf("PHYS_DIF", "Diffraction", 0.7,
          ["diffraction grating", "resolving power"],
          formulas: ["d*sin(theta) = n*lambda"]),
      _leaf("PHYS_POL", "Polarization", 0.6,
          ["polaroid", "brewster", "plane of vibration"],
          formulas: ["tan(theta) = n", "I = I0*cos^2(theta)"]),
    ]);
    for (final c in optics.children) {
      c.parent = optics;
    }
    root.children.add(optics);

    final waves = SyllabusNode(
        id: "PHYS_WAV",
        nameEn: "Waves & Sound",
        subject: "Physics",
        topic: "Waves",
        keywords: ["wave", "sound", "doppler"]);
    waves.children.addAll([
      _leaf("PHYS_WMO", "Wave Motion", 0.5,
          ["stationary wave", "travelling wave", "superposition"],
          formulas: ["v = f*lambda", "y = A*sin(omega*t - k*x)"]),
      _leaf("PHYS_SOU", "Sound Waves", 0.55, [
        "velocity of sound",
        "beats",
        "doppler effect"
      ], formulas: [
        "v = sqrt(gamma*RT/M)",
        "f_beat = |f1-f2|",
        "f' = f*(v+-v0)/(v-+vs)"
      ]),
      _leaf("PHYS_PIP", "Waves in Pipes & Strings", 0.6,
          ["closed pipe", "open pipe", "resonance"],
          formulas: ["Open pipe: f1 = v/2L", "Closed pipe: f1 = v/4L"]),
    ]);
    for (final c in waves.children) {
      c.parent = waves;
    }
    root.children.add(waves);

    final elec = SyllabusNode(
        id: "PHYS_ELE",
        nameEn: "Electricity & Magnetism",
        subject: "Physics",
        topic: "Electricity",
        keywords: ["electric", "magnetic", "circuit"]);
    elec.children.addAll([
      _leaf("PHYS_EST", "Electrostatics", 0.6, [
        "coulomb",
        "gauss",
        "electric field",
        "potential",
        "capacitor"
      ], formulas: [
        "F = k*q1*q2/r^2",
        "E = kQ/r^2",
        "V = kQ/r",
        "C = epsilon0*A/d",
        "U = 0.5*C*V^2"
      ], examples: [
        _ex(
            "Two charges +q and -q at distance d. Field at midpoint?",
            [
              "E1 = 4kq/d^2 toward -q",
              "E2 = 4kq/d^2 toward -q",
              "E_total = 8kq/d^2"
            ],
            "8kq/d^2",
            "Fields add vectorially."),
        _ex("Capacitance of parallel plate depends on?", ["C = epsilon*A/d"],
            "Geometry and dielectric", "Independent of Q and V.")
      ]),
      _leaf("PHYS_DCC", "DC Circuits", 0.55, [
        "ohm",
        "kirchhoff",
        "wheatstone",
        "potentiometer"
      ], formulas: [
        "V = IR",
        "R = rho*L/A",
        "Series: R = R1+R2",
        "Parallel: 1/R = 1/R1+1/R2",
        "KCL: sum I_in = sum I_out",
        "KVL: sum V = 0",
        "P = VI = I^2*R"
      ], examples: [
        _ex(
            "Three resistors 2,3,6 ohm in parallel. Find R_eq.",
            ["1/R = 1/2+1/3+1/6 = 1", "R = 1 ohm"],
            "1 ohm",
            "Parallel: reciprocals add.")
      ]),
      _leaf("PHYS_THE", "Thermoelectricity", 0.6,
          ["seebeck", "peltier", "thermocouple"]),
      _leaf("PHYS_MAG", "Magnetic Effects", 0.65, [
        "biot savart",
        "ampere",
        "torque",
        "galvanometer"
      ], formulas: [
        "dB = (mu0/4pi)*Idl*sin(theta)/r^2",
        "Torque = NIAB*sin(theta)"
      ]),
      _leaf("PHYS_EMI", "Electromagnetic Induction", 0.7, [
        "faraday",
        "self induction",
        "mutual induction",
        "transformer"
      ], formulas: [
        "epsilon = -N*d(phi)/dt",
        "Self: epsilon = -L*dI/dt",
        "Transformer: V2/V1 = N2/N1"
      ]),
      _leaf("PHYS_AC", "Alternating Currents", 0.65, [
        "rms",
        "phasor",
        "power factor",
        "quality factor"
      ], formulas: [
        "I_rms = I0/sqrt(2)",
        "Z = sqrt(R^2+(XL-XC)^2)",
        "cos(phi) = R/Z",
        "f_res = 1/(2pi*sqrt(LC))"
      ]),
    ]);
    for (final c in elec.children) {
      c.parent = elec;
    }
    root.children.add(elec);

    final modern = SyllabusNode(
        id: "PHYS_MOD",
        nameEn: "Modern Physics",
        subject: "Physics",
        topic: "Modern",
        keywords: ["quantum", "nuclear", "semiconductor"]);
    modern.children.addAll([
      _leaf("PHYS_PHO", "Photoelectric Effect", 0.6,
          ["planck", "work function", "einstein"],
          formulas: ["E = h*nu", "h*nu = phi + KE_max", "KE_max = e*V0"]),
      _leaf("PHYS_BOH", "Bohr's Theory & Spectra", 0.65, [
        "bohr",
        "hydrogen spectrum",
        "energy levels"
      ], formulas: [
        "r_n = n^2*r1",
        "E_n = -13.6/n^2 eV",
        "1/lambda = R(1/n1^2 - 1/n2^2)"
      ]),
      _leaf("PHYS_MAT", "Matter Waves & Uncertainty", 0.7,
          ["de broglie", "heisenberg", "x-ray"],
          formulas: ["lambda = h/p", "delta_x * delta_p >= h/(4pi)"]),
      _leaf("PHYS_SEM", "Semiconductors", 0.6, [
        "pn junction",
        "diode",
        "transistor",
        "logic gates"
      ], formulas: [
        "ne*nh = ni^2",
        "IE = IC + IB",
        "beta = IC/IB = alpha/(1-alpha)"
      ], examples: [
        _ex(
            "Transistor beta=50, IB=20uA. Find IC.",
            ["IC = 50*20uA", "IC = 1000uA = 1mA"],
            "1 mA",
            "Current amplification.")
      ]),
      _leaf("PHYS_NUC", "Nuclear Physics", 0.65, [
        "radioactivity",
        "fission",
        "fusion",
        "half life"
      ], formulas: [
        "N = N0*e^(-lambda*t)",
        "t_half = ln2/lambda",
        "E = mc^2"
      ]),
    ]);
    for (final c in modern.children) {
      c.parent = modern;
    }
    root.children.add(modern);
    return root;
  }

  static SyllabusNode _buildChemistryTree() {
    final root = SyllabusNode(
        id: "CHEM_ROOT",
        nameEn: "Chemistry",
        subject: "Chemistry",
        topic: "Root");
    final physical = SyllabusNode(
        id: "CHEM_PHY",
        nameEn: "Physical Chemistry",
        subject: "Chemistry",
        topic: "Physical");
    physical.children.addAll([
      _leaf("CHEM_STO", "Stoichiometry", 0.4, [
        "mole",
        "equivalent",
        "avogadro"
      ], formulas: [
        "n = w/M = V/22.4 (STP)",
        "M = n/V(L)",
        "N = n-factor * M",
        "N1V1 = N2V2"
      ], examples: [
        _ex("Moles in 11.2 L CO2 at STP?", ["n = 11.2/22.4"], "0.5 mole",
            "Standard molar volume.")
      ]),
      _leaf("CHEM_GAS", "Gaseous State", 0.5,
          ["ideal gas", "kinetic theory", "van der waals"],
          formulas: ["PV = nRT", "(P+an^2/V^2)(V-nb) = nRT"]),
      _leaf("CHEM_SOL", "Solid State", 0.6, [
        "crystal",
        "unit cell",
        "packing"
      ], formulas: [
        "Packing eff = Z*(4/3)*pi*r^3 / a^3",
        "FCC: a = 2*sqrt(2)*r"
      ]),
      _leaf("CHEM_ATM", "Atomic Structure", 0.55,
          ["bohr", "quantum numbers", "orbital"],
          formulas: ["E_n = -13.6*Z^2/n^2", "r_n = 0.529*n^2/Z"]),
      _leaf("CHEM_BON", "Chemical Bonding", 0.6, [
        "covalent",
        "ionic",
        "hybridization",
        "vsepr"
      ], formulas: [
        "Bond order = 0.5*(Nb-Na)",
        "mu = q*d"
      ], examples: [
        _ex("Hybridization of C in CH4?", ["4 sigma bonds -> sp3"], "sp3",
            "4 electron domains."),
        _ex(
            "Highest bond angle? NH3, H2O, CH4, CO2",
            ["CO2 linear = 180", "CH4=109.5, NH3=107, H2O=104.5"],
            "CO2 (180 degrees)",
            "Lone pairs compress bond angles.")
      ]),
      _leaf("CHEM_EQU", "Chemical Equilibrium", 0.65, [
        "ksp",
        "le chatelier",
        "ph"
      ], formulas: [
        "Kc = [Products]/[Reactants]",
        "pH = -log[H+]",
        "pH + pOH = 14"
      ]),
      _leaf("CHEM_ELE", "Electrochemistry", 0.7, [
        "nernst",
        "faraday",
        "cell potential"
      ], formulas: [
        "E0_cell = E0_cathode - E0_anode",
        "E = E0 - (0.0591/n)*logQ",
        "m = (E*I*t)/96500"
      ], examples: [
        _ex(
            "Faradays to deposit 108g Ag?",
            ["Eq.wt = 108/1 = 108", "Q = 96500 C = 1F"],
            "1 F",
            "Monovalent silver.")
      ]),
      _leaf("CHEM_THE", "Thermodynamics & Kinetics", 0.7, [
        "enthalpy",
        "entropy",
        "activation energy"
      ], formulas: [
        "deltaG = deltaH - T*deltaS",
        "k = A*e^(-Ea/RT)",
        "For all T spontaneous: dH<0, dS>0"
      ]),
    ]);
    for (final c in physical.children) {
      c.parent = physical;
    }
    root.children.add(physical);

    final inorganic = SyllabusNode(
        id: "CHEM_INO",
        nameEn: "Inorganic Chemistry",
        subject: "Chemistry",
        topic: "Inorganic");
    inorganic.children.addAll([
      _leaf("CHEM_PER", "Periodic Table", 0.5,
          ["periodicity", "ionization", "electronegativity"]),
      _leaf("CHEM_SBL", "s-Block Elements", 0.5,
          ["alkali", "alkaline earth", "downs process"]),
      _leaf("CHEM_PBL", "p-Block Elements", 0.6, [
        "nitrogen",
        "halogen",
        "sulfur",
        "noble gas"
      ], examples: [
        _ex(
            "Bleaching powder from Cl2 over?",
            ["Moist slaked lime: Ca(OH)2 + Cl2 -> CaOCl2 + H2O"],
            "Moist slaked lime",
            "Moisture required.")
      ]),
      _leaf("CHEM_DBL", "d-Block & Coordination", 0.7, [
        "transition metals",
        "coordination compounds",
        "cft"
      ], formulas: [
        "Primary valency = oxidation state",
        "Secondary valency = coordination number"
      ], examples: [
        _ex(
            "[Co(NH3)6]Cl3: Primary valency of Co?",
            ["3 Cl- balance complex", "Oxidation state = +3"],
            "3",
            "Primary valency = oxidation state.")
      ]),
      _leaf("CHEM_MET", "Metallurgy", 0.55,
          ["extraction", "roasting", "smelting"]),
    ]);
    for (final c in inorganic.children) {
      c.parent = inorganic;
    }
    root.children.add(inorganic);

    final organic = SyllabusNode(
        id: "CHEM_ORG",
        nameEn: "Organic Chemistry",
        subject: "Chemistry",
        topic: "Organic");
    organic.children.addAll([
      _leaf("CHEM_IUP", "IUPAC & Isomerism", 0.5, [
        "nomenclature",
        "isomerism",
        "tautomerism"
      ], examples: [
        _ex("IUPAC of CH3-CH(Br)-CH3?", ["3C chain = propane", "Br at C2"],
            "2-bromopropane", "Lowest locant rule.")
      ]),
      _leaf("CHEM_HYD", "Hydrocarbons", 0.55, [
        "alkane",
        "alkene",
        "alkyne",
        "aromatic"
      ], formulas: [
        "CnH2n+2 (alkane)",
        "CnH2n (alkene)",
        "CnH2n-2 (alkyne)"
      ], examples: [
        _ex(
            "Benzene + Cl2 (FeCl3) gives?",
            ["Electrophilic substitution", "C6H5Cl + HCl"],
            "Chlorobenzene",
            "FeCl3 is Lewis acid catalyst.")
      ]),
      _leaf("CHEM_HAL", "Haloalkanes & Haloarenes", 0.6,
          ["sn1", "sn2", "grignard"]),
      _leaf("CHEM_ALC", "Alcohols, Phenols & Ethers", 0.6,
          ["alcohol", "phenol", "williamson"]),
      _leaf("CHEM_ALD", "Aldehydes, Ketones & Acids", 0.65, [
        "aldehyde",
        "ketone",
        "tollens",
        "fehling"
      ], examples: [
        _ex(
            "Tollens reagent detects?",
            ["Oxidizes aldehydes to acids", "Silver mirror test"],
            "Aldehydes",
            "Ketones generally do not react.")
      ]),
      _leaf("CHEM_AMI", "Amines & Nitro Compounds", 0.65,
          ["amine", "diazotization", "sandmeyer"]),
      _leaf("CHEM_BIO", "Biomolecules & Polymers", 0.6,
          ["carbohydrate", "protein", "polymerization"]),
    ]);
    for (final c in organic.children) {
      c.parent = organic;
    }
    root.children.add(organic);
    return root;
  }

  static SyllabusNode _buildMathTree() {
    final root = SyllabusNode(
        id: "MATH_ROOT",
        nameEn: "Mathematics",
        subject: "Mathematics",
        topic: "Root");
    final algebra = SyllabusNode(
        id: "MATH_ALG",
        nameEn: "Algebra",
        subject: "Mathematics",
        topic: "Algebra");
    algebra.children.addAll([
      _leaf("MATH_SET", "Sets & Functions", 0.4,
          ["set", "function", "domain", "range"],
          formulas: ["n(A∪B) = n(A)+n(B)-n(A∩B)"]),
      _leaf("MATH_MAT", "Matrices & Determinants", 0.55, [
        "matrix",
        "determinant",
        "inverse",
        "cramers"
      ], formulas: [
        "|AB| = |A||B|",
        "|A^-1| = 1/|A|",
        "|kA| = k^n|A|",
        "A^-1 = adj(A)/|A|"
      ], examples: [
        _ex("|A|=5 for 3x3 matrix. Find |2A|.", ["|2A| = 2^3 * 5 = 40"], "40",
            "Determinant scaling rule.")
      ]),
      _leaf("MATH_COM", "Permutation & Combination", 0.6, [
        "permutation",
        "combination",
        "binomial"
      ], formulas: [
        "nPr = n!/(n-r)!",
        "nCr = n!/(r!(n-r)!)",
        "(a+b)^n = sum nCr*a^(n-r)*b^r"
      ], examples: [
        _ex("Ways to arrange 5 students?", ["5! = 120"], "120",
            "Permutation of distinct objects.")
      ]),
      _leaf("MATH_CPX", "Complex Numbers", 0.6, [
        "complex",
        "argand",
        "de moivre"
      ], formulas: [
        "|z| = sqrt(a^2+b^2)",
        "z^-1 = z_bar/|z|^2",
        "(cosθ+isinθ)^n = cos(nθ)+isin(nθ)"
      ]),
      _leaf("MATH_SEQ", "Sequence & Series", 0.55, [
        "ap",
        "gp",
        "hp",
        "infinite series"
      ], formulas: [
        "AP: Tn=a+(n-1)d, Sn=n/2[2a+(n-1)d]",
        "GP: Tn=ar^(n-1), Sn=a(1-r^n)/(1-r)",
        "S_inf = a/(1-r) for |r|<1"
      ], examples: [
        _ex("Sum of first 10 natural numbers?", ["S10 = 10*11/2 = 55"], "55",
            "AP formula.")
      ]),
    ]);
    for (final c in algebra.children) {
      c.parent = algebra;
    }
    root.children.add(algebra);

    final trig = SyllabusNode(
        id: "MATH_TRI",
        nameEn: "Trigonometry",
        subject: "Mathematics",
        topic: "Trigonometry");
    trig.children.addAll([
      _leaf("MATH_TEQ", "Trigonometric Equations", 0.55, [
        "general solution",
        "inverse trig"
      ], formulas: [
        "sinθ=0 -> θ=nπ",
        "cosθ=0 -> θ=(2n+1)π/2",
        "sinθ=sinα -> θ=nπ+(-1)^n*α"
      ], examples: [
        _ex("General solution of sinθ=0?", ["θ = nπ, n∈Z"], "θ = nπ",
            "Sine zero at integer multiples of π.")
      ]),
      _leaf("MATH_PRO", "Properties of Triangles", 0.65, [
        "sine rule",
        "cosine rule",
        "circumradius"
      ], formulas: [
        "a/sinA = b/sinB = c/sinC = 2R",
        "cosA = (b^2+c^2-a^2)/2bc",
        "Δ = 0.5*ab*sinC"
      ]),
    ]);
    for (final c in trig.children) {
      c.parent = trig;
    }
    root.children.add(trig);

    final coord = SyllabusNode(
        id: "MATH_COO",
        nameEn: "Coordinate Geometry",
        subject: "Mathematics",
        topic: "Coordinate");
    coord.children.addAll([
      _leaf("MATH_LIN", "Straight Lines", 0.5, [
        "slope",
        "intercept",
        "distance"
      ], formulas: [
        "m = (y2-y1)/(x2-x1)",
        "y = mx+c",
        "Distance = |Ax1+By1+C|/sqrt(A^2+B^2)"
      ], examples: [
        _ex("Slope of 3x+4y=12?", ["4y=-3x+12", "y=-0.75x+3"], "-3/4",
            "Slope-intercept form.")
      ]),
      _leaf("MATH_CIR", "Circles", 0.6, [
        "tangent",
        "normal",
        "chord"
      ], formulas: [
        "(x-h)^2+(y-k)^2=r^2",
        "x^2+y^2=r^2 (origin)"
      ], examples: [
        _ex("Circle center (0,0), radius 5?", ["x^2+y^2=25"], "x^2+y^2=25",
            "Standard form.")
      ]),
      _leaf("MATH_CON", "Conic Sections", 0.7, [
        "parabola",
        "ellipse",
        "hyperbola",
        "eccentricity"
      ], formulas: [
        "Parabola: y^2=4ax, e=1",
        "Ellipse: x^2/a^2+y^2/b^2=1, e<1",
        "Hyperbola: x^2/a^2-y^2/b^2=1, e>1"
      ], examples: [
        _ex("Eccentricity of parabola?", ["e=1 by definition"], "1",
            "Parabola e=1, Ellipse e<1, Hyperbola e>1, Circle e=0.")
      ]),
    ]);
    for (final c in coord.children) {
      c.parent = coord;
    }
    root.children.add(coord);

    final calculus = SyllabusNode(
        id: "MATH_CAL",
        nameEn: "Calculus",
        subject: "Mathematics",
        topic: "Calculus");
    calculus.children.addAll([
      _leaf("MATH_LIM", "Limits & Continuity", 0.55, [
        "limit",
        "l hospital",
        "continuity"
      ], formulas: [
        "lim(x->0) sinx/x = 1",
        "lim(x->0) (1+x)^(1/x) = e",
        "L'Hopital: lim f/g = lim f'/g'"
      ], examples: [
        _ex("lim(x->0) sin(x)/x = ?", ["Standard limit = 1"], "1",
            "Fundamental limit.")
      ]),
      _leaf("MATH_DER", "Differentiation", 0.6, [
        "derivative",
        "chain rule",
        "maxima minima"
      ], formulas: [
        "d/dx(x^n) = n*x^(n-1)",
        "d/dx(sinx)=cosx",
        "d/dx(cosx)=-sinx",
        "d/dx(e^x)=e^x",
        "Chain: dy/dx = dy/du * du/dx",
        "Product: d(uv)=udv+vdu"
      ], examples: [
        _ex("Derivative of x^5?", ["5*x^4"], "5x^4", "Power rule.")
      ]),
      _leaf("MATH_INT", "Integration", 0.65, [
        "integral",
        "definite integral",
        "area"
      ], formulas: [
        "∫x^n dx = x^(n+1)/(n+1)+C",
        "∫1/x dx = ln|x|+C",
        "∫e^x dx = e^x+C",
        "∫sinx dx = -cosx+C",
        "∫cosx dx = sinx+C",
        "Parts: ∫u dv = uv - ∫v du",
        "King: ∫0^a f(x)dx = ∫0^a f(a-x)dx"
      ], examples: [
        _ex("∫ 3x^2 dx = ?", ["3*x^3/3 + C"], "x^3 + C",
            "Power rule integration.")
      ]),
      _leaf("MATH_DEQ", "Differential Equations", 0.7, [
        "variable separable",
        "homogeneous",
        "linear"
      ], formulas: [
        "Order: highest derivative",
        "Degree: power of highest derivative"
      ]),
    ]);
    for (final c in calculus.children) {
      c.parent = calculus;
    }
    root.children.add(calculus);

    final vector = SyllabusNode(
        id: "MATH_VEC",
        nameEn: "Vectors",
        subject: "Mathematics",
        topic: "Vectors");
    vector.children.addAll([
      _leaf("MATH_VOP", "Vector Operations", 0.6, [
        "dot product",
        "cross product",
        "triple product"
      ], formulas: [
        "a·b = |a||b|cosθ",
        "|a×b| = |a||b|sinθ",
        "a·b = a1b1+a2b2+a3b3"
      ], examples: [
        _ex("|a|=3, |b|=4, a·b=6. Find angle.",
            ["cosθ = 6/(3*4) = 0.5", "θ = 60°"], "60°", "Dot product formula.")
      ]),
    ]);
    for (final c in vector.children) {
      c.parent = vector;
    }
    root.children.add(vector);

    final stats = SyllabusNode(
        id: "MATH_STA",
        nameEn: "Statistics & Probability",
        subject: "Mathematics",
        topic: "Statistics");
    stats.children.addAll([
      _leaf("MATH_PROB", "Probability", 0.55, [
        "bayes",
        "binomial",
        "conditional"
      ], formulas: [
        "P(A∪B) = P(A)+P(B)-P(A∩B)",
        "P(A|B) = P(A∩B)/P(B)",
        "Binomial: P(r) = nCr*p^r*q^(n-r)"
      ], examples: [
        _ex("P(Head) for fair coin?", ["1/2 = 0.5"], "0.5",
            "Sample space {H,T}."),
        _ex(
            "Probability of getting sum 7 with two dice?",
            [
              "Favorable: (1,6),(2,5),(3,4),(4,3),(5,2),(6,1) = 6",
              "Total = 36",
              "P = 6/36 = 1/6"
            ],
            "1/6",
            "Count favorable outcomes.")
      ]),
      _leaf("MATH_COR", "Correlation & Regression", 0.6,
          ["correlation", "regression line"]),
    ]);
    for (final c in stats.children) {
      c.parent = stats;
    }
    root.children.add(stats);
    return root;
  }

  static SyllabusNode _buildBiologyTree() {
    final root = SyllabusNode(
        id: "BIO_ROOT", nameEn: "Biology", subject: "Biology", topic: "Root");
    final zoology = SyllabusNode(
        id: "BIO_ZOO", nameEn: "Zoology", subject: "Biology", topic: "Zoology");
    zoology.children.addAll([
      _leaf("BIO_EVO", "Evolutionary Biology", 0.5, [
        "darwin",
        "lamarck",
        "human evolution"
      ], definitions: [
        "Natural selection: Survival of fittest.",
        "Speciation: Formation of new species."
      ]),
      _leaf("BIO_ANI", "Animal Diversity", 0.55,
          ["classification", "phylum", "chordata"]),
      _leaf("BIO_TIS", "Animal Tissues", 0.5, [
        "epithelial",
        "connective",
        "muscular",
        "nervous"
      ], definitions: [
        "Epithelial: Covering tissue.",
        "Connective: Supporting tissue.",
        "Muscular: Movement.",
        "Nervous: Conduction."
      ]),
      _leaf("BIO_HUM", "Human Physiology", 0.65, [
        "digestive",
        "respiratory",
        "circulatory",
        "excretory",
        "nervous"
      ], formulas: [
        "Hb + 4O2 ⇌ Hb(O2)4"
      ], definitions: [
        "SA node: Pacemaker of heart.",
        "Cardiac cycle: Atrial systole → Ventricular systole → Joint diastole.",
        "Nephrons: Functional units of kidney."
      ], examples: [
        _ex(
            "Which enzyme digests proteins in stomach?",
            ["Pepsin activated by HCl from pepsinogen."],
            "Pepsin",
            "Chief cells secrete pepsinogen."),
        _ex("Pacemaker of heart?", ["SA node generates action potential."],
            "SA node", "Located in right atrium."),
        _ex("Photosynthesis occurs in?", ["Chloroplast contains chlorophyll."],
            "Chloroplast", "Light reactions in thylakoids, dark in stroma.")
      ]),
      _leaf("BIO_REP", "Reproduction & Development", 0.6,
          ["gametogenesis", "embryo", "ivf"]),
      _leaf("BIO_IMM", "Microbial Diseases & Immunity", 0.6,
          ["typhoid", "hiv", "vaccine", "immunity"]),
    ]);
    for (final c in zoology.children) {
      c.parent = zoology;
    }
    root.children.add(zoology);

    final botany = SyllabusNode(
        id: "BIO_BOT", nameEn: "Botany", subject: "Biology", topic: "Botany");
    botany.children.addAll([
      _leaf("BIO_BIO", "Biodiversity", 0.55, [
        "monera",
        "fungi",
        "angiosperm",
        "gymnosperm"
      ], definitions: [
        "Five kingdom: Monera, Protista, Fungi, Plantae, Animalia (Whittaker 1969)."
      ]),
      _leaf("BIO_ECO", "Ecology", 0.5, [
        "ecosystem",
        "greenhouse",
        "succession"
      ], definitions: [
        "Primary consumer: Herbivore.",
        "Trophic level: Position in food chain."
      ]),
      _leaf("BIO_CEL", "Cell Biology", 0.6, [
        "mitosis",
        "meiosis",
        "organelle"
      ], definitions: [
        "Mitosis: Equational division (2n→2n).",
        "Meiosis: Reductional division (2n→n).",
        "Synapsis: Pairing in prophase I only.",
        "Metaphase: Best stage for karyotyping."
      ], examples: [
        _ex(
            "Chromosomes best observed during?",
            ["Metaphase: align at equator, most condensed."],
            "Metaphase",
            "Best for karyotyping.")
      ]),
      _leaf("BIO_GEN", "Genetics", 0.65, [
        "dna",
        "rna",
        "mendel",
        "mutation"
      ], formulas: [
        "A-T (2 H-bonds)",
        "G-C (3 H-bonds)"
      ], definitions: [
        "Mendel's 1st: Law of dominance.",
        "Mendel's 2nd: Law of segregation.",
        "Mendel's 3rd: Law of independent assortment.",
        "DNA: Double helix, antiparallel, semiconservative replication."
      ], examples: [
        _ex(
            "Mendel's law of independent assortment based on?",
            ["Dihybrid cross gave 9:3:3:1 ratio."],
            "Dihybrid cross",
            "Two traits studied simultaneously.")
      ]),
      _leaf("BIO_PHY", "Plant Physiology", 0.6, [
        "photosynthesis",
        "transpiration",
        "growth regulator"
      ], definitions: [
        "Photosynthesis: 6CO2 + 6H2O → C6H12O6 + 6O2",
        "Transpiration: Loss of water vapor from aerial parts."
      ]),
    ]);
    for (final c in botany.children) {
      c.parent = botany;
    }
    root.children.add(botany);
    return root;
  }

  static SyllabusNode _buildEnglishTree() {
    final root = SyllabusNode(
        id: "ENG_ROOT", nameEn: "English", subject: "English", topic: "Root");
    root.children.addAll([
      _leaf("ENG_GR1", "Grammar I (Tense, Voice, Speech)", 0.5, [
        "tense",
        "active",
        "passive",
        "reported"
      ], definitions: [
        "Active voice: Subject performs action.",
        "Passive voice: Subject receives action (be + past participle).",
        "Reported speech: Backshift present→past, am→was, this→that, now→then."
      ], examples: [
        _ex(
            "Change to passive: Teacher praised student.",
            ["Student was praised by teacher."],
            "The student was praised by the teacher.",
            "Object becomes subject + be + V3 + by + agent.")
      ]),
      _leaf("ENG_GR2", "Grammar II (Structures, Verbals)", 0.55, [
        "gerund",
        "infinitive",
        "participle"
      ], definitions: [
        "Gerund: Verb+ing functioning as noun.",
        "Infinitive: to + base verb.",
        "Participle: Verb form used as adjective."
      ]),
      _leaf("ENG_PHO", "Phonetics", 0.45, [
        "vowel",
        "consonant",
        "transcription"
      ], definitions: [
        "Vowel sounds: 20 (12 pure + 8 diphthongs).",
        "Vowel letters: A, E, I, O, U (5)."
      ]),
      _leaf("ENG_COM", "Comprehension", 0.6,
          ["reading", "inference", "main idea"]),
      _leaf("ENG_VOC", "Vocabulary", 0.5, ["synonym", "antonym", "analogy"]),
    ]);
    for (final c in root.children) {
      c.parent = root;
    }
    return root;
  }

  static SyllabusNode _buildMatTree() {
    final root = SyllabusNode(
        id: "MAT_ROOT",
        nameEn: "Mental Agility Test",
        subject: "MAT",
        topic: "Root");
    root.children.addAll([
      _leaf("MAT_VER", "Verbal Reasoning", 0.5, [
        "analogy",
        "classification",
        "odd one out"
      ], examples: [
        _ex(
            "Odd one out: Rose, Lily, Lotus, Mango",
            ["Mango is fruit, others are flowers."],
            "Mango",
            "Category difference.")
      ]),
      _leaf("MAT_NUM", "Numerical Reasoning", 0.55, [
        "series",
        "pattern",
        "missing number"
      ], examples: [
        _ex(
            "Next: 2, 6, 12, 20, 30, ...",
            ["Pattern: 1*2, 2*3, 3*4, 4*5, 5*6", "Next = 6*7 = 42"],
            "42",
            "n*(n+1) pattern.")
      ]),
      _leaf("MAT_LOG", "Logical Sequencing", 0.6, [
        "blood relation",
        "direction",
        "coding"
      ], examples: [
        _ex(
            "A is brother of B, B is sister of C, C is father of D. A related to D?",
            ["A is brother of C", "C is father of D", "A is uncle of D"],
            "Uncle",
            "Trace relations step by step.")
      ]),
      _leaf("MAT_SPA", "Spatial Reasoning", 0.6,
          ["mirror image", "paper folding", "figure counting"]),
    ]);
    for (final c in root.children) {
      c.parent = root;
    }
    return root;
  }

  static SyllabusNode _buildHealthTree() {
    final root = SyllabusNode(
        id: 'HLTH_ROOT',
        nameEn: 'Pre-requisite Health Knowledge',
        subject: 'Health Knowledge',
        topic: 'Root');
    root.children.addAll([
      _leaf('HLTH_DET', 'Determinants of Health and Illness', 0.5, [
        'determinants',
        'prevention',
        'risk factor'
      ], definitions: [
        'Social determinants of health include the conditions in which people are born, grow, learn, work, and age.',
        'Primary prevention acts before disease begins, while secondary prevention emphasizes early detection and treatment.',
      ]),
      _leaf(
          'HLTH_COM', 'Communicable, Vector-borne and Zoonotic Diseases', 0.6, [
        'communicable',
        'vector',
        'zoonosis'
      ],
          definitions: [
            'A communicable disease can be transmitted directly or indirectly from an infectious source to a susceptible host.',
            'A zoonosis is an infection naturally transmitted between vertebrate animals and humans.',
          ]),
      _leaf('HLTH_NCD', 'Non-communicable Diseases', 0.55, [
        'non-communicable',
        'screening',
        'lifestyle'
      ], definitions: [
        'Non-communicable diseases are not spread person to person and commonly have long duration and multifactorial causes.',
        'Modifiable risk factors include tobacco use, harmful alcohol use, unhealthy diet, and physical inactivity.',
      ]),
      _leaf('HLTH_WASH', 'Water, Sanitation and Hygiene', 0.5, [
        'water',
        'sanitation',
        'hygiene'
      ], definitions: [
        'Safe water, sanitation, and hand hygiene interrupt transmission of many enteric infections.',
        'Faecal contamination can be interrupted through safe disposal, clean water, food hygiene, and handwashing.',
      ]),
      _leaf('HLTH_EPI', 'Biostatistics and Epidemiology', 0.65, [
        'incidence',
        'prevalence',
        'epidemiology'
      ], definitions: [
        'Incidence measures new cases occurring in a population at risk during a defined period.',
        'Prevalence measures all existing cases in a population at a specified time or over a period.',
      ]),
    ]);
    for (final child in root.children) {
      child.parent = root;
    }
    return root;
  }

  // Helper constructors
  static SyllabusNode _leaf(
      String id, String name, double diff, List<String> keywords,
      {List<String>? formulas,
      List<String>? definitions,
      List<WorkedExample>? examples}) {
    return SyllabusNode(
      id: id,
      nameEn: name,
      subject: id.startsWith("PHYS")
          ? "Physics"
          : id.startsWith("CHEM")
              ? "Chemistry"
              : id.startsWith("MATH")
                  ? "Mathematics"
                  : id.startsWith("BIO")
                      ? "Biology"
                      : id.startsWith("ENG")
                          ? "English"
                          : id.startsWith('HLTH')
                              ? 'Health Knowledge'
                              : "MAT",
      topic: name,
      difficulty: diff,
      keywords: keywords,
      formulas: formulas ?? [],
      definitions: definitions ?? [],
      examples: examples ?? [],
    );
  }

  static WorkedExample _ex(
      String problem, List<String> steps, String answer, String explanation) {
    return WorkedExample(
        problem: problem,
        steps: steps,
        finalAnswer: answer,
        explanation: explanation);
  }
}

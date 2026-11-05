import 'package:flutter/widgets.dart';

import 'l10n.dart';

/// Display labels for fixed option values. The stored value stays in English
/// (it is what the database and search filters use); only the label shown to
/// the member is translated. Unknown values are shown as they are.
extension OptionLabels on BuildContext {
  String optionLabel(String value) {
    final l = l10n;
    switch (value) {
      // Religion
      case 'Hindu':
        return l.religionHindu;
      case 'Muslim':
        return l.religionMuslim;
      case 'Christian':
        return l.religionChristian;
      case 'Sikh':
        return l.religionSikh;
      case 'Jain':
        return l.religionJain;
      case 'Buddhist':
        return l.religionBuddhist;
      case 'Other':
        return l.optionOther;
      // Marital status
      case 'Never Married':
        return l.maritalNeverMarried;
      case 'Divorced':
        return l.maritalDivorced;
      case 'Widowed':
        return l.maritalWidowed;
      case 'Separated':
        return l.maritalSeparated;
      // Gender
      case 'Male':
      case 'male':
        return l.genderMale;
      case 'Female':
      case 'female':
        return l.genderFemale;
      // Profile created by
      case 'self':
        return l.createdBySelf;
      case 'sibling':
        return l.createdBySibling;
      case 'parents':
        return l.createdByParents;
      case 'guardian':
        return l.createdByGuardian;
      // Work status
      case 'business':
        return l.workBusiness;
      case 'salaried':
        return l.workSalaried;
      case 'not_working':
        return l.workNotWorking;
      default:
        return value;
    }
  }
}

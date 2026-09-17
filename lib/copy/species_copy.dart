import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/profile_provider.dart';

abstract final class SpeciesCopy {
  static String noun(PetSpecies? species) => switch (species) {
        PetSpecies.dog => AppCopy.petNounDog,
        null => AppCopy.petNounFallback,
      };
}

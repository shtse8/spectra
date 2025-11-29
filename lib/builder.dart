import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator/spectra_generator.dart';

/// Builder factory for Spectra code generator.
Builder spectraBuilder(BuilderOptions options) => SharedPartBuilder(
      [SpectraGenerator()],
      'spectra_schema',
    );

import 'dart:typed_data';

import 'package:hive_ce/hive_ce.dart';
import 'package:keyva/core/database/models/kdf_parameters.dart';
import 'package:keyva/core/database/models/security_settings.dart';
import 'package:keyva/core/database/models/user_record.dart';
import 'package:keyva/core/database/models/vault_record.dart';
import 'package:keyva/core/database/models/wrapped_vault_key.dart';

@GenerateAdapters([
  AdapterSpec<UserRecord>(),
  AdapterSpec<KdfParameters>(),
  AdapterSpec<WrappedVaultKey>(),
  AdapterSpec<SecuritySettings>(),
  AdapterSpec<VaultRecord>(),
])
part 'hive_adapters.g.dart';

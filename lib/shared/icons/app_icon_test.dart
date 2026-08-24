import 'package:flutter/material.dart';
import 'package:keyva/shared/icons/app_icons.dart';

class AppIconTestPage extends StatelessWidget {
  const AppIconTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <String, Map<String, IconData>>{
      'Vault': {
        'lock': AppIcon.lock,
        'lockOpen': AppIcon.lockOpen,
        'key': AppIcon.key,
        'shield': AppIcon.shield,
        'shieldCheck': AppIcon.shieldCheck,
        'password': AppIcon.password,
        'passwordCheck': AppIcon.passwordCheck,
        'eye': AppIcon.eye,
        'eyeOff': AppIcon.eyeOff,
        'fingerprint': AppIcon.fingerprint,
        'pin': AppIcon.pin,
        'itemPin': AppIcon.itemPin,
        'itemUnpin': AppIcon.itemUnpin,
        'masterPassword': AppIcon.masterPassword,
      },

      'Information Types': {
        'login': AppIcon.login,
        'accountCircle': AppIcon.accountCircle,
        'creditCard': AppIcon.creditCard,
        'note': AppIcon.note,
        'stickyNote': AppIcon.stickyNote,
        'folder': AppIcon.folder,
        'folderPlus': AppIcon.folderPlus,
        'tag': AppIcon.tag,
      },

      'Actions': {
        'add': AppIcon.add,
        'edit': AppIcon.edit,
        'delete': AppIcon.delete,
        'copy': AppIcon.copy,
        'check': AppIcon.check,
        'close': AppIcon.close,
        'save': AppIcon.save,
        'done': AppIcon.done,
        'cancel': AppIcon.cancel,
        'search': AppIcon.search,
        'filter': AppIcon.filter,
        'sort': AppIcon.sort,
      },

      'Navigation': {
        'home': AppIcon.home,
        'menu': AppIcon.menu,
        'arrowBack': AppIcon.arrowBack,
        'arrowForward': AppIcon.arrowForward,
        'chevronRight': AppIcon.chevronRight,
        'chevronLeft': AppIcon.chevronLeft,
        'keyboardArrowDown': AppIcon.keyboardArrowDown,
        'keyboardArrowUp': AppIcon.keyboardArrowUp,
      },

      'Settings': {
        'settings': AppIcon.settings,
        'security': AppIcon.security,
        'notifications': AppIcon.notifications,
        'language': AppIcon.language,
        'palette': AppIcon.palette,
        'darkMode': AppIcon.darkMode,
        'lightMode': AppIcon.lightMode,
        'systemTheme': AppIcon.systemTheme,
        'backup': AppIcon.backup,
        'restore': AppIcon.restore,
        'privacy': AppIcon.privacy,
        'info': AppIcon.info,
        'logout': AppIcon.logout,
      },

      'Password Generator': {
        'shuffle': AppIcon.shuffle,
        'refresh': AppIcon.refresh,
        'tune': AppIcon.tune,
        'visibility': AppIcon.visibility,
        'visibilityOff': AppIcon.visibilityOff,
      },

      'Security': {
        'lockClock': AppIcon.lockClock,
        'noPhotography': AppIcon.noPhotography,
        'verifiedUser': AppIcon.verifiedUser,
        'warning': AppIcon.warning,
        'error': AppIcon.error,
        'checkCircle': AppIcon.checkCircle,
      },

      'Backup & Restore': {
        'cloudUpload': AppIcon.cloudUpload,
        'cloudDownload': AppIcon.cloudDownload,
        'fileUpload': AppIcon.fileUpload,
        'fileDownload': AppIcon.fileDownload,
        'download': AppIcon.download,
        'upload': AppIcon.upload,
      },

      'Notifications & Status': {'notificationsOff': AppIcon.notificationsOff},
    };

    return Scaffold(
      appBar: AppBar(title: const Text('App Icons')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sections.entries.map((section) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: Text(
                  section.key,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: section.value.entries.map((icon) {
                  return Container(
                    width: 100,
                    height: 90,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon.value, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          icon.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

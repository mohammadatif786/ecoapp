import 'dart:io';
import 'dart:math';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_up/constants/wizard_constants.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/helper/app_config.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:link_up/theme/linkup_text_styles.dart';
import 'package:link_up/ui/auth/signup_wizard/wizard_location_picker.dart';
import 'package:link_up/ui/auth/signup_wizard/wizard_otp_sheet.dart';

/// 15-step wizard aligned with web `Wizard.vue` (steps 2–16; avatar step skipped).
class SignupWizardScreen extends StatefulWidget {
  const SignupWizardScreen({super.key});

  @override
  State<SignupWizardScreen> createState() => _SignupWizardScreenState();
}

class _SignupWizardScreenState extends State<SignupWizardScreen> {
  static const int totalSteps = 15;

  final AuthController _auth = Get.find(tag: AuthController().toString());
  final ImagePicker _picker = ImagePicker();

  int _step = 1;
  String? _selectedLanguage;
  String _selectedWhy = '';
  String _countryIso2 = '';
  final Set<String> _selectedInterests = {'Cooking'};
  bool _phoneOtpVerified = false;
  final List<File?> _photoFiles = List.filled(6, null);

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _auth.language.value.isNotEmpty
        ? _auth.language.value
        : WizardConstants.languages.first;
    _countryIso2 = _auth.NewCountry.value;
    _auth.distanceKm.value = 40;
    _auth.ageRangeValues.value = const RangeValues(18, 50);
  }

  Future<void> _next() async {
    final error = _validateStep();
    if (error != null) {
      _auth.alert1(error);
      return;
    }

    // Web step 4: phone OTP before advancing.
    if (_step == 3 && !_phoneOtpVerified) {
      await _requestPhoneOtp();
      return;
    }

    if (_step >= totalSteps) {
      await _finishWizard();
      return;
    }

    setState(() => _step++);
  }

  Future<void> _requestPhoneOtp() async {
    final phone = _auth.phoneNumberController.text.trim();
    if (phone.isEmpty) {
      _auth.alert1('Please enter your phone number');
      return;
    }
    final fullPhone = _auth.getFullPhoneNumber();
    try {
      _auth.updateLoading(true);
      final token = await LinkupApiService.requestPhoneOtp(fullPhone);
      _auth.updateLoading(false);
      if (!mounted) return;
      await WizardOtpSheet.show(
        context,
        phone: fullPhone,
        otpToken: token,
        onVerified: () {
          setState(() => _phoneOtpVerified = true);
          _next();
        },
      );
    } on LinkupApiException catch (e) {
      _auth.updateLoading(false);
      _auth.alert1(e.message);
    } catch (e) {
      _auth.updateLoading(false);
      _auth.alert1(e.toString());
    }
  }

  Future<void> _finishWizard() async {
    final photos =
        _photoFiles.whereType<File>().toList(growable: false);
    if (photos.length < 3) {
      _auth.alert1('Please upload at least 3 photos');
      return;
    }

    _auth.actLocation.value = _selectedWhy;
    _auth.updatelanguage(_selectedLanguage!);

    try {
      await _auth.submitWizardToApi(
        countryIso2: _countryIso2,
        interests: _selectedInterests.toList(),
        photoFiles: photos,
      );
      if (!mounted) return;
      _auth.alert1('Profile completed successfully!');
      Navigator.pushReplacementNamed(context, RoutePath.home_screen);
    } on LinkupApiException catch (e) {
      _auth.alert1(e.message);
    } catch (e) {
      _auth.alert1(e.toString());
    }
  }

  String? _validateStep() {
    switch (_step) {
      case 1:
        if (_countryIso2.isEmpty) return 'Please select a country';
        if (_auth.NewState.value.isEmpty) return 'Please select a state';
        if (_auth.NewCity.value.isEmpty) return 'Please select a city';
        return null;
      case 2:
        if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
          return 'Please select a language';
        }
        return null;
      case 3:
        if (_auth.phoneNumberController.text.trim().isEmpty) {
          return 'Please enter your phone number';
        }
        return null;
      case 4:
        if (_auth.birthday.value == 0 ||
            _auth.dobController.text == 'Select Your Birthday') {
          return 'Please select your birthdate';
        }
        if (_auth.age.value < 18) return 'You must be at least 18 years old';
        return null;
      case 5:
        if (_auth.gender.value.isEmpty) return 'Please select your gender';
        return null;
      case 6:
      case 7:
        return null;
      case 8:
        if (_auth.linkmeWith.value.isEmpty) {
          return 'Please select who you want to link up with';
        }
        return null;
      case 9:
        if (_auth.meetFromPreference.value != 'all' &&
            _auth.countryMeetFromName.value.isEmpty) {
          return 'Please select a country';
        }
        return null;
      case 10:
        if (_auth.nationalityName.value.isEmpty) {
          return 'Please select your country of origin';
        }
        return null;
      case 11:
        if (_auth.jobController.text.trim().isEmpty) {
          return 'Please enter your profession';
        }
        return null;
      case 12:
        if (_auth.universityController.text.trim().isEmpty) {
          return 'Please enter your university';
        }
        return null;
      case 13:
        if (_selectedWhy.isEmpty) return 'Please select why you are here';
        return null;
      case 14:
        if (_auth.aboutMeController.text.trim().isEmpty) {
          return 'Please tell us about yourself';
        }
        if (_selectedInterests.isEmpty) {
          return 'Please select at least one interest';
        }
        return null;
      case 15:
        if (_photoFiles.whereType<File>().length < 3) {
          return 'Please upload at least 3 photos';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _pickPhoto(int index) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _photoFiles[index] = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      init: _auth,
      builder: (_) {
        if (_auth.loading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LinkUpColors.brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _step >= totalSteps ? 'Finish' : 'next'.tr,
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              _buildHeader(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: LinearProgressIndicator(
                  value: _step / totalSteps,
                  backgroundColor: Colors.grey.shade200,
                  color: LinkUpColors.brandBlue,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildStepContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/Group 163959.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: Image.asset(
            'assets/Vector Smart Object 2.png',
            width: 150,
            height: 50,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LinkUpColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: LinkUpColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildLanguageStep();
      case 3:
        return _buildPhoneStep();
      case 4:
        return _buildBirthdayStep();
      case 5:
        return _buildGenderStep();
      case 6:
        return _buildDistanceStep();
      case 7:
        return _buildAgeRangeStep();
      case 8:
        return _buildLinkMeWithStep();
      case 9:
        return _buildMeetFromStep();
      case 10:
        return _buildRootsStep();
      case 11:
        return _buildJobStep();
      case 12:
        return _buildUniversityStep();
      case 13:
        return _buildWhyHereStep();
      case 14:
        return _buildAboutInterestsStep();
      case 15:
        return _buildPhotosStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Where do you live?',
          subtitle:
              'Tell us your home base so LinkUp can help you find events, meet people, stay connected, and go LIVE.',
        ),
        WizardLocationPicker(
          countryIso2: _countryIso2,
          stateName: _auth.NewState.value,
          cityName: _auth.NewCity.value,
          onCountryChanged: (iso2) {
            setState(() {
              _countryIso2 = iso2;
              _auth.NewCountry.value = iso2;
            });
          },
          onStateChanged: (state) => _auth.NewState.value = state,
          onCityChanged: (city) => _auth.NewCity.value = city,
        ),
      ],
    );
  }

  Widget _buildLanguageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Tell Link Up what language you speak',
          subtitle:
              'Choose your preferred language to help us connect you with others who share your linguistic background.',
        ),
        ...WizardConstants.languages.map((lang) {
          final selected = _selectedLanguage == lang;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedLanguage = lang),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? LinkUpColors.brandBlue
                        : LinkUpColors.border,
                  ),
                  color: selected
                      ? LinkUpColors.brandBlue.withValues(alpha: 0.1)
                      : Colors.white,
                ),
                child: Text(
                  lang,
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? LinkUpColors.brandBlue
                        : LinkUpColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Lets Keep in touch 📱',
          subtitle:
              'Add your phone so you can connect more easily with your match',
        ),
        TextFormField(
          controller: _auth.phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: CountryCodePicker(
              onChanged: (e) => _auth.updatePhoneNumberCode(e.dialCode!),
              initialSelection: 'BS',
              favorite: const ['BS', 'BB'],
            ),
          ),
        ),
        if (_phoneOtpVerified)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Phone verified ✔️',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildBirthdayStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          "Let's Link Up Know when to send the cake 🎂",
          subtitle:
              'Your birth date helps us display your age but the exact date is private',
        ),
        const Text('Birthdate', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _auth.selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _auth.dobController,
              decoration: InputDecoration(
                hintText: 'Select your birth date',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          "What's your gender?",
          subtitle: 'Choose the option that best describes you.',
        ),
        ...['male', 'female'].map((g) => _choiceTile(
              label: g[0].toUpperCase() + g.substring(1),
              selected: _auth.gender.value.toLowerCase() == g,
              onTap: () => _auth.updateGender(g),
            )),
      ],
    );
  }

  Widget _buildDistanceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'How far will you link up? 🎯',
          subtitle: 'Adjust your distance to meet matches near you.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Distance Preference',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${_auth.distanceKm.value.round()} km',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: _auth.distanceKm.value,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: LinkUpColors.brandBlue,
          onChanged: (v) => _auth.updateDistanceKm(v),
        ),
      ],
    );
  }

  Widget _buildAgeRangeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'What age range are you interested in? 🎯',
          subtitle: "Choose the age range of people you'd like to connect with.",
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Age Range Preference',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${_auth.ageRangeValues.value.start.round()} - ${_auth.ageRangeValues.value.end.round()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        RangeSlider(
          values: _auth.ageRangeValues.value,
          min: 18,
          max: 100,
          divisions: 82,
          activeColor: LinkUpColors.brandBlue,
          onChanged: _auth.updateAgeRangeValue,
        ),
      ],
    );
  }

  Widget _buildLinkMeWithStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Tell Link Up who you'd like to see"),
        ...['male', 'female', 'both'].map((g) => _choiceTile(
              label: g[0].toUpperCase() + g.substring(1),
              selected: _auth.linkmeWith.value.toLowerCase() == g,
              onTap: () => _auth.updateLinkMeWith(g),
            )),
      ],
    );
  }

  Widget _buildMeetFromStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Who do you want to link Up with? 🌍',
          subtitle:
              'Choose the Caribbean or Latin American countries you would like to meet people from.',
        ),
        Row(
          children: [
            Radio<String>(
              value: 'all',
              groupValue: _auth.meetFromPreference.value,
              onChanged: (v) {
                _auth.updateMeetFromValues('', 'all', '');
                _auth.updateMeetFromPreference('all');
                setState(() {});
              },
            ),
            const Text('All'),
            Radio<String>(
              value: 'other',
              groupValue: _auth.meetFromPreference.value,
              onChanged: (v) {
                _auth.updateMeetFromPreference('other');
                setState(() {});
              },
            ),
            const Text('Other'),
          ],
        ),
        if (_auth.meetFromPreference.value != 'all')
          CountryCodePicker(
            initialSelection: _auth.countryMeetFromCode.value,
            countryList: Utils.carribAndLatinCountry,
            onChanged: (e) =>
                _auth.updateMeetFromValues(e.name!, e.code!, e.dialCode!),
            showOnlyCountryWhenClosed: true,
          ),
      ],
    );
  }

  Widget _buildRootsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Tell Link Up about your roots 🌍',
          subtitle:
              "Select the country you're connected to—we'll proudly show your flag on your profile.",
        ),
        CountryCodePicker(
          initialSelection: _auth.nationalityCode.value,
          countryList: Utils.carribAndLatinCountry,
          onChanged: (e) =>
              _auth.updateNationality(e.name!, e.code!, e.dialCode!),
          showOnlyCountryWhenClosed: true,
        ),
      ],
    );
  }

  Widget _buildJobStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Tell Link Up what you do? 💼',
          subtitle:
              "What's your profession? This helps us connect you with like-minded individuals.",
        ),
        TextFormField(
          controller: _auth.jobController,
          maxLength: 255,
          decoration: InputDecoration(
            hintText: 'What do you do?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildUniversityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'What university did you attend? 🎓',
          subtitle:
              'Let Link Up know where you studied to connect with others who share your background.',
        ),
        TextFormField(
          controller: _auth.universityController,
          decoration: InputDecoration(
            hintText: 'University name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildWhyHereStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          "Tell Link Up why you're here",
          subtitle:
              "Everyone's here for something different—choose what you're looking for.",
        ),
        ...WizardConstants.whyOptions.map((item) {
          final title = item['title']!;
          final emoji = item['emoji']!;
          final description = item['description'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedWhy = title),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedWhy == title
                        ? LinkUpColors.brandBlue
                        : LinkUpColors.border,
                  ),
                  color: _selectedWhy == title
                      ? LinkUpColors.brandBlue
                      : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LinkUpEmojiText(emoji, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedWhy == title
                                  ? Colors.white
                                  : LinkUpColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedWhy == title
                              ? Colors.white70
                              : LinkUpColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAboutInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Tell Link Up about yourself',
          subtitle:
              'Share your passions to connect with others in the Caribbean and Latin American community.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _auth.aboutMeController,
                maxLines: 4,
                maxLength: 180,
                decoration: InputDecoration(
                  hintText: 'Tell Link Up a bit about yourself',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                OutlinedButton(
                  onPressed: () {
                    _auth.aboutMeController.text =
                        WizardConstants.aboutFromSelections;
                    setState(() {});
                  },
                  child: const Text('✨ From my\nselections',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    final suggestions = WizardConstants.aboutSuggestions;
                    _auth.aboutMeController.text =
                        suggestions[Random().nextInt(suggestions.length)];
                    setState(() {});
                  },
                  child: const Text('🎲 Surprise\nme',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Event interests (select all that apply, min 1)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${_selectedInterests.length} selected',
              style: const TextStyle(color: LinkUpColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WizardConstants.interests.map((interest) {
            final selected = _selectedInterests.contains(interest.label);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinkUpEmojiText(interest.icon, size: 14),
                  const SizedBox(width: 6),
                  Text(interest.label),
                ],
              ),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedInterests.add(interest.label);
                  } else {
                    _selectedInterests.remove(interest.label);
                  }
                });
              },
              selectedColor: LinkUpColors.brandBlue.withValues(alpha: 0.2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Show your best self',
          subtitle:
              'Upload up to six of your best photos. Upload at least 3 to continue.',
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            final file = _photoFiles[index];
            return GestureDetector(
              onTap: () => _pickPhoto(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LinkUpColors.brandBlue),
                  image: file != null
                      ? DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: file == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: LinkUpColors.brandBlue),
                          Text('Upload', style: TextStyle(fontSize: 10)),
                        ],
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _choiceTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? LinkUpColors.brandBlue : LinkUpColors.border,
            ),
            color: selected ? LinkUpColors.brandBlue : Colors.white,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : LinkUpColors.brandBlue,
            ),
          ),
        ),
      ),
    );
  }
}

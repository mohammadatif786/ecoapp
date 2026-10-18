import 'package:flutter/material.dart';
import 'package:link_up/services/location_api_service.dart';
import 'package:link_up/theme/linkup_colors.dart';

/// Country / state / city — countriesnow.space (same as web wizard).
class WizardLocationPicker extends StatefulWidget {
  final String countryIso2;
  final String stateName;
  final String cityName;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onCityChanged;

  const WizardLocationPicker({
    super.key,
    required this.countryIso2,
    required this.stateName,
    required this.cityName,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
  });

  @override
  State<WizardLocationPicker> createState() => _WizardLocationPickerState();
}

class _WizardLocationPickerState extends State<WizardLocationPicker> {
  List<CountryOption> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];
  bool _loadingCountries = true;
  bool _loadingStates = false;
  bool _loadingCities = false;
  String? _error;
  String? _countryIso2;
  CountryOption? _selectedCountry;
  String? _state;
  String? _city;

  @override
  void initState() {
    super.initState();
    _countryIso2 =
        widget.countryIso2.isNotEmpty ? widget.countryIso2 : null;
    _state = widget.stateName.isNotEmpty ? widget.stateName : null;
    _city = widget.cityName.isNotEmpty ? widget.cityName : null;
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await LocationApiService.fetchCountries();
      if (!mounted) return;
      CountryOption? selected;
      if (_countryIso2 != null) {
        for (final c in countries) {
          if (c.iso2 == _countryIso2) {
            selected = c;
            break;
          }
        }
      }
      setState(() {
        _countries = countries;
        _selectedCountry = selected;
        _loadingCountries = false;
      });
      if (selected != null) {
        await _loadStates(selected);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCountries = false;
          _error = 'Could not load countries. Check your connection.';
        });
      }
    }
  }

  Future<void> _loadStates(CountryOption country) async {
    setState(() {
      _loadingStates = true;
      _error = null;
      _states = [];
      _cities = [];
      _state = null;
      _city = null;
    });
    widget.onStateChanged('');
    widget.onCityChanged('');

    try {
      final states = await LocationApiService.fetchStates(
        countryIso2: country.iso2,
        countryName: country.name,
      );
      if (!mounted) return;
      setState(() {
        _states = states;
        _loadingStates = false;
        if (_state != null && states.contains(_state)) {
          _loadCities(country, _state!);
        }
      });
      if (states.isEmpty) {
        setState(() => _error = 'No states found for ${country.name}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingStates = false;
          _error = 'Could not load states for ${country.name}';
        });
      }
    }
  }

  Future<void> _loadCities(CountryOption country, String stateName) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
      _city = null;
    });
    widget.onCityChanged('');

    try {
      final cities = await LocationApiService.fetchCities(
        countryIso2: country.iso2,
        countryName: country.name,
        stateName: stateName,
      );
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  InputDecoration _decoration(String label, {Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LinkUpColors.border),
      ),
    );
  }

  Widget _flagText(String flag, String label) {
    return Row(
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCountries) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _countryIso2 != null &&
                  _countries.any((c) => c.iso2 == _countryIso2)
              ? _countryIso2
              : null,
          decoration: _decoration('Country'),
          hint: const Text('Select Country'),
          items: _countries
              .map(
                (c) => DropdownMenuItem(
                  value: c.iso2,
                  child: _flagText(c.flag, c.name),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => _countries
              .map(
                (c) => Align(
                  alignment: Alignment.centerLeft,
                  child: _flagText(c.flag, c.name),
                ),
              )
              .toList(),
          onChanged: (iso2) {
            if (iso2 == null) return;
            final country = _countries.firstWhere((c) => c.iso2 == iso2);
            setState(() {
              _countryIso2 = iso2;
              _selectedCountry = country;
            });
            widget.onCountryChanged(iso2);
            _loadStates(country);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _state != null && _states.contains(_state) ? _state : null,
          decoration: _decoration('State'),
          hint: Text(
            _loadingStates
                ? 'Loading states...'
                : _selectedCountry == null
                    ? 'Select country first'
                    : 'Select State',
          ),
          items: _states
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: _loadingStates || _selectedCountry == null
              ? null
              : (state) {
                  if (state == null) return;
                  setState(() => _state = state);
                  widget.onStateChanged(state);
                  _loadCities(_selectedCountry!, state);
                },
        ),
        if (_loadingStates)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _city != null && _cities.contains(_city) ? _city : null,
          decoration: _decoration('City'),
          hint: Text(
            _loadingCities
                ? 'Loading cities...'
                : _state == null
                    ? 'Select state first'
                    : 'Select City',
          ),
          items: _cities
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: _loadingCities || _state == null
              ? null
              : (city) {
                  if (city == null) return;
                  setState(() => _city = city);
                  widget.onCityChanged(city);
                },
        ),
        if (_loadingCities)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

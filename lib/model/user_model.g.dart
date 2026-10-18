// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      newCity1: json['new_city'] as String? ?? '',
      newCountry1: json['new_country'] as String? ?? '',
      newState1: json['new_state'] as String? ?? '',
      uid: json['uid'] as String?,
      fcmToken: json['fcmToken'] as String?,
      aboutMe: json['about_me'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      birthday: (json['birthday'] as num?)?.toInt() ?? 0,
      age: (json['age'] as num?)?.toInt() ?? 20,
      country: json['country'] as String? ?? 'Bahamas',
      countryCode: json['country_code'] as String? ?? 'BS',
      phoneNumberDialCode: json['phone_number_dial_code'] as String? ?? '+1242',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Male',
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      job: json['job'] as String? ?? '',
      morePhotos: (json['more_photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      linkWithMePhoneCode:
          json['link_with_me_phone_code'] as String? ?? '+1242',
      phoneNumber: json['phone_number'] as String? ?? '',
      status: json['status'] as bool? ?? true,
      whyarewehere: json['whyare'] as String? ?? 'Bahamas',
      university: json['university'] as String? ?? '',
      ageFilter: (json['age_filter'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['19', '50'],
      distanceFilter: (json['distance_filter'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['10', '1000'],
      isGhost: json['is_ghost'] as bool? ?? false,
      isClub: json['is_club'] as bool? ?? false,
      isRestaurant: json['is_restaurant'] as bool? ?? false,
      isTopShelf: json['is_top_shelf'] as bool? ?? false,
      isLiveStream: json['is_live_streaming'] as bool? ?? false,
      language: json['language'] as String? ?? 'English',
      linkMeWith: json['link_me_with'] as String? ?? 'Female',
      linkMeWithCountryCode:
          json['link_me_with_country_code'] as String? ?? 'BS',
      whichLatinCountryYouLinkedWith:
          json['which_latin_country_you_linked_with'] as String? ?? 'Bahamas',
      newMatchNotification: json['new_match_notification'] as bool? ?? true,
      newMessageNotification: json['new_message_notification'] as bool? ?? true,
      promotionNotification: json['promotion_notification'] as bool? ?? true,
      lastActive: (json['last_active'] as num).toInt(),
      createdAt: (json['created_at'] as num).toInt(),
      updatedAt: (json['updated_at'] as num).toInt(),
      subscription: json['subscription'] as List<dynamic>? ?? [],
      stripeCustomerId: json['stripe_customer_id'] as String? ?? '',
      distance: json['distance'] as String?,
      showMyAge: json['show_age'] as bool? ?? false,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'uid': instance.uid,
      'fcmToken': instance.fcmToken,
      'about_me': instance.aboutMe,
      'avatar': instance.avatar,
      'birthday': instance.birthday,
      'age': instance.age,
      'country': instance.country,
      'country_code': instance.countryCode,
      'phone_number_dial_code': instance.phoneNumberDialCode,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'new_country': instance.newCountry1,
      'new_state': instance.newState1,
      'new_city': instance.newCity1,
      'gender': instance.gender,
      'interests': instance.interests,
      'job': instance.job,
      'more_photos': instance.morePhotos,
      'link_with_me_phone_code': instance.linkWithMePhoneCode,
      'phone_number': instance.phoneNumber,
      'status': instance.status,
      'whyare': instance.whyarewehere,
      'university': instance.university,
      'age_filter': instance.ageFilter,
      'distance_filter': instance.distanceFilter,
      'which_latin_country_you_linked_with':
          instance.whichLatinCountryYouLinkedWith,
      'is_ghost': instance.isGhost,
      'is_club': instance.isClub,
      'is_restaurant': instance.isRestaurant,
      'is_top_shelf': instance.isTopShelf,
      'is_live_streaming': instance.isLiveStream,
      'language': instance.language,
      'link_me_with': instance.linkMeWith,
      'link_me_with_country_code': instance.linkMeWithCountryCode,
      'new_match_notification': instance.newMatchNotification,
      'new_message_notification': instance.newMessageNotification,
      'promotion_notification': instance.promotionNotification,
      'last_active': instance.lastActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'show_age': instance.showMyAge,
      'subscription': instance.subscription,
      'stripe_customer_id': instance.stripeCustomerId,
      'distance': instance.distance,
    };

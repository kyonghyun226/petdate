/// Preferred meetup windows. Separate from P03 lifestyle tags.
enum PreferredTimeSlot {
  weekdayMorning,
  weekdayAfternoon,
  weekdayEvening,
  weekendMorning,
  weekendAfternoon,
  weekendEvening,
}

abstract final class PreferredTimeCopy {
  static const labels = {
    PreferredTimeSlot.weekdayMorning: '평일 아침',
    PreferredTimeSlot.weekdayAfternoon: '평일 오후',
    PreferredTimeSlot.weekdayEvening: '평일 저녁',
    PreferredTimeSlot.weekendMorning: '주말 아침',
    PreferredTimeSlot.weekendAfternoon: '주말 오후',
    PreferredTimeSlot.weekendEvening: '주말 저녁',
  };

  static String label(PreferredTimeSlot slot) => labels[slot]!;
}

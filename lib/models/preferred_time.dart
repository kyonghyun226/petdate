/// Preferred meetup windows. Separate from P03 lifestyle tags.
enum PreferredTimeSlot { weekdayEvening, weekendMorning, weekendAfternoon }

abstract final class PreferredTimeCopy {
  static const labels = {
    PreferredTimeSlot.weekdayEvening: '평일 저녁',
    PreferredTimeSlot.weekendMorning: '주말 아침',
    PreferredTimeSlot.weekendAfternoon: '주말 오후',
  };

  static String label(PreferredTimeSlot slot) => labels[slot]!;
}

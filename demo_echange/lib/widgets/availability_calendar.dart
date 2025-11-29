// widgets/availability_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../models/Reservation.dart';
import '../providers/reservation_provider.dart';

class AvailabilityCalendar extends StatefulWidget {
  final String itemId;

  const AvailabilityCalendar({Key? key, required this.itemId}) : super(key: key);

  @override
  _AvailabilityCalendarState createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendrier de disponibilité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildCalendarContent(),
            SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    final reservationProvider = Provider.of<ReservationProvider>(context);

    // Check if we have any reservation data
    final hasReservationData = reservationProvider.reservations.isNotEmpty ||
        reservationProvider.receivedReservations.isNotEmpty;

    if (!hasReservationData) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 50, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucune donnée de réservation',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Le calendrier s\'affichera lorsque des réservations seront créées',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    try {
      final reservations = _getItemReservations(reservationProvider);
      final bookedDates = _getBookedDates(reservations);

      return TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDateCell(day, bookedDates);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildTodayCell(day, bookedDates);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildSelectedCell(day, bookedDates);
          },
        ),
      );
    } catch (e) {
      print('Error building calendar: $e');
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Erreur d\'affichage du calendrier',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      );
    }
  }

  List<Reservation> _getItemReservations(ReservationProvider provider) {
    try {
      // Get all reservations for this item
      final allReservations = [...provider.reservations, ...provider.receivedReservations];
      return allReservations.where((reservation) =>
      reservation.itemId == widget.itemId &&
          (reservation.status == 'pending' || reservation.status == 'accepted')
      ).toList();
    } catch (e) {
      print('Error getting item reservations: $e');
      return [];
    }
  }

  Set<DateTime> _getBookedDates(List<Reservation> reservations) {
    final bookedDates = <DateTime>{};

    for (final reservation in reservations) {
      try {
        final days = reservation.endDate.difference(reservation.startDate).inDays;
        for (int i = 0; i <= days; i++) {
          final date = reservation.startDate.add(Duration(days: i));
          bookedDates.add(DateTime(date.year, date.month, date.day));
        }
      } catch (e) {
        print('Error processing reservation dates: $e');
      }
    }

    return bookedDates;
  }

  Widget _buildDateCell(DateTime day, Set<DateTime> bookedDates) {
    final isBooked = bookedDates.contains(DateTime(day.year, day.month, day.day));
    final isPast = day.isBefore(DateTime.now().subtract(Duration(days: 1)));

    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isBooked
            ? Colors.red.withOpacity(0.3)
            : isPast
            ? Colors.grey.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBooked ? Colors.red : Colors.transparent,
        ),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isBooked ? Colors.red :
            isPast ? Colors.grey : Colors.black,
            fontWeight: isBooked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCell(DateTime day, Set<DateTime> bookedDates) {
    final isBooked = bookedDates.contains(DateTime(day.year, day.month, day.day));

    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isBooked ? Colors.red : Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCell(DateTime day, Set<DateTime> bookedDates) {
    final isBooked = bookedDates.contains(DateTime(day.year, day.month, day.day));

    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isBooked ? Colors.red : Colors.blue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isBooked ? Colors.white : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Disponible', Colors.green),
        _buildLegendItem('Réservé', Colors.red),
        _buildLegendItem('Aujourd\'hui', Colors.blue),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
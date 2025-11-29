// widgets/availability_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Reservation.dart';
import '../services/firebase-service.dart';

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
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadItemReservations();
  }

  Future<void> _loadItemReservations() async {
    try {
      final FirebaseFirestore _firestore = FirebaseService.firestore;

      final querySnapshot = await _firestore
          .collection('reservations')
          .where('itemId', isEqualTo: widget.itemId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      setState(() {
        _reservations = querySnapshot.docs
            .map((doc) => Reservation.fromMap(doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading item reservations: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

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
            SizedBox(height: 8),
            Text(
              'Dates rouges = Déjà réservé',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
    if (_isLoading) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Chargement des disponibilités...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadItemReservations,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final bookedDates = _getBookedDates(_reservations);

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
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mois',
        CalendarFormat.twoWeeks: '2 semaines',
        CalendarFormat.week: 'Semaine',
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
        outsideBuilder: (context, day, focusedDay) {
          return _buildOutsideCell(day, bookedDates);
        },
      ),
    );
  }

  Set<DateTime> _getBookedDates(List<Reservation> reservations) {
    final bookedDates = <DateTime>{};

    for (final reservation in reservations) {
      try {
        final start = DateTime(reservation.startDate.year, reservation.startDate.month, reservation.startDate.day);
        final end = DateTime(reservation.endDate.year, reservation.endDate.month, reservation.endDate.day);

        // Add all dates between start and end (inclusive)
        DateTime current = start;
        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
          bookedDates.add(DateTime(current.year, current.month, current.day));
          current = current.add(Duration(days: 1));
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
    final isToday = isSameDay(day, DateTime.now());

    if (isPast && !isToday) {
      return Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isBooked
            ? Colors.red.withOpacity(0.3)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBooked ? Colors.red : Colors.transparent,
          width: isBooked ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isBooked ? Colors.red : Colors.black,
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
        border: Border.all(
          color: isBooked ? Colors.red : Colors.blue,
          width: 2,
        ),
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

  Widget _buildOutsideCell(DateTime day, Set<DateTime> bookedDates) {
    final isPast = day.isBefore(DateTime.now().subtract(Duration(days: 1)));

    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Légende:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('Disponible', Colors.green),
            _buildLegendItem('Réservé', Colors.red),
            _buildLegendItem('Aujourd\'hui', Colors.blue),
            _buildLegendItem('Passé', Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color,
              width: 1,
            ),
          ),
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
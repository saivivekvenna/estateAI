import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class SwiperPage extends StatefulWidget {
  const SwiperPage({super.key});

  @override
  _SwiperPageState createState() => _SwiperPageState();
}

class _SwiperPageState extends State<SwiperPage> {
  final CardSwiperController controller = CardSwiperController();
  final List<PropertyCard> cards = [];
  bool hasCards = true;

  @override
  void initState() {
    super.initState();
    // Add some sample property cards
    cards.add(
      PropertyCard(
        imageUrl:
            'https://images.unsplash.com/photo-1564013799919-ab600027ffc6',
        price: '\$250,000',
        address: '123 Main Street, Cityville',
        bedrooms: 3,
        bathrooms: 2,
        area: '1,500 sqft',
      ),
    );
    cards.add(
      PropertyCard(
        imageUrl:
            'https://images.unsplash.com/photo-1568605114967-8130f3a36994',
        price: '\$320,000',
        address: '456 Park Avenue, Townsville',
        bedrooms: 4,
        bathrooms: 3,
        area: '2,200 sqft',
      ),
    );
    cards.add(
      PropertyCard(
        imageUrl:
            'https://images.unsplash.com/photo-1576941089067-2de3c901e126',
        price: '\$180,000',
        address: '789 Oak Drive, Villageton',
        bedrooms: 2,
        bathrooms: 1,
        area: '950 sqft',
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          primary: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 200,
          flexibleSpace: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 0, top: 4, right: 0),
                  child: Container(
                    height: 60,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(143, 206, 157, 1),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_alt_rounded,
                        color: Colors.black,
                        size: 35,
                      ),
                      onPressed: () {
                        // Add action for left button
                      },
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(left: 0, top: 4, right: 0),
                  child: Container(
                    height: 60,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(143, 206, 157, 1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.star_rounded,
                        color: Colors.yellow,
                        size: 35,
                      ),
                      onPressed: () {
                        // Add action for right button
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: hasCards && cards.isNotEmpty
          ? Container(
              padding: const EdgeInsets.only(top: 120, bottom: 20),
              child: CardSwiper(
                controller: controller,
                cardsCount: cards.length,
                onSwipe: (int previousIndex, int? currentIndex,
                    CardSwiperDirection direction) {
                  // Handle swipe actions
                  if (currentIndex == null) {
                    // No more cards
                    setState(() {
                      hasCards = false;
                    });
                  }
                  return true;
                },
                onUndo: (int? previousIndex, int currentIndex,
                    CardSwiperDirection direction) {
                  // Handle undo action
                  return true;
                },
                numberOfCardsDisplayed: 3,
                backCardOffset: const Offset(40, 40),
                padding: const EdgeInsets.all(24.0),
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) =>
                        cards[index],
              ),
            )
          : noHousesScreen(),
      bottomNavigationBar: hasCards && cards.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'reject',
                    backgroundColor: Color.fromRGBO(143, 206, 157, 1),
                    onPressed: () {
                      controller.swipe(CardSwiperDirection.left);
                    },
                    child: const Icon(Icons.close, color: Colors.red, size: 30),
                  ),
                  FloatingActionButton(
                    heroTag: 'undo',
                    backgroundColor: Color.fromRGBO(143, 206, 157, 1),
                    onPressed: () {
                      controller.undo();
                    },
                    child:
                        const Icon(Icons.replay, color: Colors.blue, size: 30),
                  ),
                  FloatingActionButton(
                    heroTag: 'accept',
                    backgroundColor: Color.fromRGBO(143, 206, 157, 1),
                    onPressed: () {
                      controller.swipe(CardSwiperDirection.right);
                    },
                    child: const Icon(Icons.favorite,
                        color: Colors.green, size: 30),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class PropertyCard extends StatelessWidget {
  final String imageUrl;
  final String price;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final String area;

  const PropertyCard({
    Key? key,
    required this.imageUrl,
    required this.price,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromRGBO(52, 99, 56, 1),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [ 
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Image.network(
                imageUrl,
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.error)),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              height: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeature(Icons.bed, '$bedrooms Beds'),
                        _buildFeature(Icons.bathtub, '$bathrooms Baths'),
                        _buildFeature(Icons.square_foot, area),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(),
        ),
      ],
    );
  }
}

Widget noHousesScreen() {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(10.0),
          child: Text('Cant find anything with your filter!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
        SizedBox(height: 25),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 150),
          child: Text(
            'Try changing your filters',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      ],
    ),
  );
}

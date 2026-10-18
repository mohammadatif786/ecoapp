// import 'package:flutter/material.dart';
// import 'package:flutter/src/widgets/container.dart';
// import 'package:flutter/src/widgets/framework.dart';

// class MultipleTicketType extends StatelessWidget {
  

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: Drawer(
//         backgroundColor: Color(0XFF4E5B81),
//         child: DrawerScreen(),
//       ),
//       backgroundColor: Colors.white,
//       body: Stack(children: [
//         Container(
//           height: 150,
//           width: double.infinity,
//           decoration: BoxDecoration(
//               image: DecorationImage(
//                   image: AssetImage("assets/Group 163959 (1).jpg"),
//                   fit: BoxFit.cover)),
//           child: Padding(
//             padding: const EdgeInsets.only(bottom: 30, left: 10),
//             child: Row(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 10),
//                   child: IconButton(
//                     onPressed: () {
//                       _scaffoldKey.currentState!.openDrawer();
//                     },
//                     icon: const Icon(Icons.menu),
//                     color: Colors.white,
//                     iconSize: 35,
//                   ),
//                 ),
//                 SizedBox(
//                   width: 20,
//                 ),
//                 Text(
//                   'Ticket Type',
//                   style: TextStyle(
//                       color: Color.fromARGB(255, 255, 255, 255), fontSize: 18),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         ListView(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 130),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Container(
//                     width: 100,
//                     color: Color.fromARGB(255, 56, 171, 216),
//                     child: TextButton(
//                         onPressed: () {
//                           setState(() {
//                             butn = vip;
//                           });
//                         },
//                         child: Text(
//                           "\$${vip.toString()}",
//                           style: TextStyle(color: Colors.white, fontSize: 20),
//                         )),
//                   ),
//                   Container(
//                     width: 100,
//                     color: Color.fromRGBO(214, 220, 22, 1),
//                     child: TextButton(
//                       onPressed: () {
//                         setState(() {
//                           butn = ecnmy;
//                         });
//                       },
//                       child: Text(
//                         "\$${ecnmy.toString()}",
//                         style: TextStyle(color: Colors.white, fontSize: 20),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//             // (widget.earlybrdVip.toString()==null || widget.earlybirtheconomy.toString()==null)?
//             // Padding(
//             //   padding: const EdgeInsets.only(top: 140),
//             //   child: Row(
//             //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             //       children: [
//             //         Text(widget.vip_price.toString()),
//             //         Text(widget.economy_price.toString()),
//             //       ]
//             //       ),
//             // ):
//             //  Padding(
//             //   padding: const EdgeInsets.only(top: 140),
//             //   child: Row(
//             //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             //       children: [
//             //         Text(widget.earlybirtheconomy.toString()),
//             //         Text(widget.earlybrdVip.toString()),
//             //       ]
//             //       ),
//             // ),

//             // Padding(
//             //   padding: const EdgeInsets.only(top: 190),
//             //   child: Row(
//             //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             //     children: [
//             //       Container(
//             //         color: Color.fromARGB(255, 56, 171, 216),
//             //         child: DropdownButton(
//             //             value: dropdownvalue,
//             //             icon: const Icon(Icons.keyboard_arrow_down),
//             //             items: items.map((String items) {
//             //               return DropdownMenuItem(
//             //                 value: items,
//             //                 child: Text(items),
//             //               );
//             //             }).toList(),
//             //             onChanged: (String? newValue) {
//             //               setState(() {
//             //                 button = dropdownvalue = newValue.toString();
//             //                 // // print(button);
//             //               });
//             //             }),
//             //       ),

//             //       SizedBox(
//             //         width: 5,
//             //       ),
//             //       Container(
//             //         color: Color.fromRGBO(214, 220, 22, 1),
//             //         child: DropdownButton(
//             //             value: dropdownvalue2,
//             //             icon: const Icon(Icons.keyboard_arrow_down),
//             //             items: items2.map((String items2) {
//             //               return DropdownMenuItem(
//             //                 value: items2,
//             //                 child: Text(items2),
//             //               );
//             //             }).toList(),
//             //             onChanged: (String? newValue) {
//             //               setState(() {
//             //                 button = dropdownvalue2 = newValue.toString();
//             //                 // // print(button);
//             //               });
//             //             }),
//             //       ),

//             // GestureDetector(
//             //   onTap: () {
//             //     setState(() {
//             //       button = widget.earlybrdVip.toString();
//             //       // // print(button);
//             //     });
//             //   },
//             //   child: Container(
//             //     height: 40,
//             //     width: 160,
//             //     decoration: BoxDecoration(
//             //         color: Color.fromARGB(255, 56, 171, 216),
//             //         borderRadius: BorderRadius.circular(3)),
//             //     child: Row(
//             //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             //       children: [
//             //         Text(
//             //           "Early Bird VIP",
//             //          style: TextStyle(color: Colors.white, fontSize: 16),
//             //         ),
//             //         SizedBox(
//             //           width: 10,
//             //         ),
//             //         // Text(widget.earlybrdVip.toString(),
//             //             // style:
//             //                 // TextStyle(color: Colors.white, fontSize: 15)),
//             //         Icon(
//             //           Icons.arrow_drop_down,
//             //           color: Colors.white,
//             //           size: 30,
//             //         ),
//             //       ],
//             //     ),
//             //   ),
//             // ),
//             //  SizedBox(
//             //   width: 10,
//             //  ),
//             // GestureDetector(
//             //   onTap: () {
//             //     setState(() {
//             //       button = widget.earlybirtheconomy.toString();
//             //       // // print(button);
//             //     });
//             //   },
//             //   child: Container(
//             //     height: 40,
//             //     width: 160,
//             //     decoration: BoxDecoration(
//             //         color: Color.fromRGBO(214, 220, 22, 1),
//             //         borderRadius: BorderRadius.circular(3)),
//             //     child: Row(
//             //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             //       children: [
//             //         Text(
//             //           "Regular VIP",
//             //          style: TextStyle(color: Colors.white, fontSize: 16),
//             //         ),
//             //         SizedBox(
//             //           width: 10,
//             //         ),
//             //         // Icon(
//             //         //   Icons.arrow_drop_down,
//             //         //   color: Colors.white,
//             //         //   size: 30,
//             //         // ),
//             //         Text(widget.earlybirtheconomy.toString(),
//             //             style:
//             //                 TextStyle(color: Colors.white, fontSize: 15)),
//             //       ],
//             //     ),
//             //   ),
//             // )
//             //     ],
//             //   ),
//             // ),
//             SizedBox(
//               height: 30,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20),
//                   child: InkWell(
//                     onTap: _decrementCounter,
//                     child: Container(
//                       height: 30,
//                       width: 30,
//                       decoration: BoxDecoration(
//                           color: Color.fromARGB(251, 217, 217, 217),
//                           borderRadius: BorderRadius.circular(3)),
//                       child: Center(
//                           child: Text(
//                         '-',
//                         style: TextStyle(fontSize: 30),
//                       )),
//                     ),
//                   ),
//                 ),
//                 Text(
//                   '$_counter',
//                   style: Theme.of(context).textTheme.headline4,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(right: 20),
//                   child: InkWell(
//                     onTap: _incrementCounter,
//                     child: Container(
//                       height: 30,
//                       width: 30,
//                       decoration: BoxDecoration(
//                           color: Color.fromARGB(251, 217, 217, 217),
//                           borderRadius: BorderRadius.circular(3)),
//                       child: Icon(Icons.add),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Divider(
//               indent: 20,
//               endIndent: 20,
//             ),
//             Row(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 20, left: 20),
//                   child: Text(
//                     "Event Category:",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 10,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 20),
//                   child: Text(
//                     widget.category.toString(),
//                     style: TextStyle(
//                       fontSize: 18,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(
//               height: 10,
//             ),
//             Obx(
//               () => SizedBox(
//                 height: 30,
//                 width: double.infinity,
//                 child: FutureBuilder(
//                   future: _firestore
//                       .collection('coupons')
//                       .where('ticket_id',
//                           isEqualTo: entcontroller.ticketid!.value)
//                       .get(),
//                   builder: (BuildContext context, AsyncSnapshot snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Center(
//                         child: CircularProgressIndicator(),
//                       );
//                     }
//                     if (snapshot.hasError) {
//                       return Center(
//                         child: Text('Error: ${snapshot.error}'),
//                       );
//                     }
//                     print(snapshot.data.docs.toString());
//                     if (snapshot.data.docs.length != 0) {
//                       return InkWell(
//                         onTap: () {
//                           var ticket_id1 = snapshot.data.docs[0].id;
//                           print(ticket_id1);

//                           Navigator.push(context,
//                               MaterialPageRoute(builder: (_) {
//                             return CouponScreen(
//                               id: entcontroller.ticketid!.value.toString(),
//                             );
//                           }));
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.only(left: 30),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Apply Coupon",
//                                 style: TextStyle(
//                                     fontSize: 14, color: Colors.black38),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.only(right: 20),
//                                 child: Icon(
//                                   Icons.arrow_right,
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   size: 30,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     } else {
//                       return Padding(
//                         padding: const EdgeInsets.only(left: 30),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               "no Coupon Available",
//                               style: TextStyle(
//                                   fontSize: 14, color: Colors.black38),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.only(right: 20),
//                               child: Icon(
//                                 Icons.arrow_right,
//                                 color: Color.fromARGB(255, 56, 171, 216),
//                                 size: 30,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ),

//             Divider(
//               indent: 20,
//               endIndent: 20,
//             ),
//             // Padding(
//             //   padding: const EdgeInsets.only(top: 30, left: 20),
//             //   child: Row(
//             //     crossAxisAlignment: CrossAxisAlignment.end,
//             //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             //     textBaseline: TextBaseline.alphabetic,
//             //     children: [
//             //       Text(
//             //         "Pay from wallet\nLinkup Event Balance",
//             //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             //       ),
//             //       Padding(
//             //         padding: const EdgeInsets.only(right: 10),
//             //         child: Icon(
//             //           Icons.arrow_right,
//             //           color: Color.fromARGB(255, 56, 171, 216),
//             //           size: 30,
//             //         ),
//             //       ),
//             //     ],
//             //   ),
//             // ),
//             // Padding(
//             //   padding: const EdgeInsets.only(top: 10, left: 20),
//             //   child: Text(
//             //     "Available for Payment \$65.0",
//             //     style: TextStyle(fontSize: 14, color: Colors.black38),
//             //   ),
//             // ),
//             // Divider(
//             //   indent: 20,
//             //   endIndent: 20,
//             // ),
//             // SizedBox(
//             //   height: 10,
//             // ),

//             Row(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20),
//                   child: Text(
//                     "Coupon Discount",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 50,
//                 ),

//                 Obx(() => entcontroller.percentageoramount == 2
//                     ? Text(
//                         "-" +
//                             entcontroller.percentage!.value.toString() +
//                             ' % ',
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red),
//                       )
//                     : entcontroller.percentageoramount == 1
//                         ? Text(
//                             "-" +
//                                 ' \$ ' +
//                                 entcontroller.discount!.value.toString(),
//                             style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.red),
//                           )
//                         : Container())
//                 // Text(FirebaseAuth.instance.currentUser!.uid.toString()),
//               ],
//             ),
//             (discountt == 0)
//                 ? SizedBox()
//                 : Divider(
//                     indent: 20,
//                     endIndent: 20,
//                   ),
//             SizedBox(
//               height: 80,
//             ),
//             Center(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   (total1 == 0.0)
//                       ? SizedBox()
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Text(
//                               "Total",
//                               style: TextStyle(
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                             Text(
//                               "\$" + equal2.toString(),
//                               style: TextStyle(
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                   (total1 == 0.0)
//                       ? SizedBox()
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             Text(
//                               "!Tax:",
//                               style: TextStyle(
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                             Row(
//                               children: [
//                                 Text(
//                                   "%",
//                                   style: TextStyle(
//                                       color: Color.fromARGB(255, 56, 171, 216),
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 Text(
//                                   tax1.toString(),
//                                   style: TextStyle(
//                                       color: Color.fromARGB(255, 56, 171, 216),
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                   (total1 == 0.0)
//                       ? SizedBox()
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             Text(
//                               "!Fees:",
//                               style: TextStyle(
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                             Text(
//                               "%${fee}",
//                               style: TextStyle(
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold),
//                             )
//                           ],
//                         ),
//                   (total1 == 0.0)
//                       ? SizedBox()
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             Text(
//                               "Total:",
//                               style: TextStyle(
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                             Text(
//                               "\$" + total1.toString(),
//                               style: TextStyle(
//                                   color: Color.fromARGB(255, 56, 171, 216),
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                 ],
//               ),
//             ),
//             SizedBox(
//               height: 20,
//             ),
//             // Text(widget.uid.toString()),
//             Center(
//               child: InkWell(
//                   onTap: () {
//                     if (total1 == 0.0) {
//                       Text(":");
//                     } else {
//                       Navigator.push(context, MaterialPageRoute(builder: (_) {
//                         return Event9(
//                           totalprice: total1,
//                           title: widget.title,
//                           description: widget.description,
//                           end_time: widget.end_time,
//                           start_time: widget.start_time,
//                           country: widget.country,
//                           state: widget.state,
//                           uid: widget.uid,
//                           Disclaimer: widget.disclaimer,
//                           venue: widget.venue,
//                           Organizer: widget.organizer,
//                           image: widget.image,
//                         );
//                       }));
//                     }
//                   },
//                   child: Container(
//                     height: 40,
//                     width: 260,
//                     decoration: BoxDecoration(
//                         color: total1 == 0.0
//                             ? Color.fromRGBO(214, 220, 22, 1)
//                             : Color.fromRGBO(214, 220, 22, 1),
//                         borderRadius: BorderRadius.circular(3)),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.only(left: 20),
//                           child: Text(
//                             total1 == 0.0 ? "Select Ticket Price" : "CONTINUE",
//                             style: TextStyle(color: Colors.white, fontSize: 18),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )),
//             )
//           ],
//         ),
//       ]),
//     );
//   }

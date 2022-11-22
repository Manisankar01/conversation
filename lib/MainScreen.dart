// import 'package:conversation/SampleHomeScreen.dart';
// import 'package:conversation/ViewModel/ChatMessageViewModel.dart';
// import 'package:conversation/ViewModel/ChatRoomsViewModel.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:provider/provider.dart';
//
// class MainScreen extends StatelessWidget {
//   const MainScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(
//             create: (BuildContext context) => ChatRoomsViewModel()),
//         ChangeNotifierProvider(
//             create: (BuildContext context) => ChatMessageViewModel())
//       ],
//       child: const SampleHomeScreen(),
//     );
//   }
// }
//
// //ChangeNotifierProvider<ChatRoomsViewModel>(
// //       create: (BuildContext context) => ChatRoomsViewModel(),
// //       child:const SampleHomeScreen(),
// //     )

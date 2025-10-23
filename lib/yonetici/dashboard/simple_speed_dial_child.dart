import 'package:flutter/material.dart';

const double figmaDesingHeight=812.0;
const double figmaDesingWidth=375.0;

double heightFactor(BuildContext context,double heightInFigma){
  return MediaQuery.of(context).size.height*(heightInFigma/figmaDesingHeight);
}
double widthFactor(BuildContext context,double widhtInFigma){
  return MediaQuery.of(context).size.height*(widhtInFigma/figmaDesingWidth);
}

class CustomSizedBox extends StatelessWidget{
  final double? width;
  final double? height;
  final Widget? child;
  const CustomSizedBox({super.key, this.height,this.child,this.width});

  @override
  Widget build(BuildContext context){
    return SizedBox(
      width: width!= null ? widthFactor(context,width!):null,
      height: height!= null ? heightFactor(context,height!):null,
      child: child,
    );
  }



}



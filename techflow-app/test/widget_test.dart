import 'package:flutter_test/flutter_test.dart';
import 'package:techflow_app/main.dart';

void main() {
  testWidgets('login entry renders key sections', (tester) async {
    await tester.pumpWidget(const TechFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('TechFlow Mobile Workspace'), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('立即登录'), findsOneWidget);
    expect(find.text('短信验证码登录'), findsOneWidget);
    expect(find.text('手机号或邮箱'), findsOneWidget);
    expect(find.text('登录密码'), findsOneWidget);
  });
}

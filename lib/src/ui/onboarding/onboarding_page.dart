import 'package:food_app/src/imports/core_imports.dart';
import 'package:food_app/src/imports/packages_imports.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      gradientStart: Color(0xFFEA580C),
      gradientEnd: Color(0xFFF97316),
      icon: Icons.access_time_rounded,
      emoji: '🕐',
      title: 'Right Recipe,\nRight Time',
      subtitle:
          'Breakfast at dawn, lunch at noon, dinner at dusk — your feed adapts to your clock automatically.',
    ),
    _OnboardingSlide(
      gradientStart: Color(0xFF7C3AED),
      gradientEnd: Color(0xFFEC4899),
      icon: Icons.location_on_rounded,
      emoji: '📍',
      title: 'Discover Your\nNeighbourhood Flavours',
      subtitle:
          'Your location shapes what you see. Italian, Japanese, Mexican — recipes that feel like home.',
    ),
    _OnboardingSlide(
      gradientStart: Color(0xFF059669),
      gradientEnd: Color(0xFF10B981),
      icon: Icons.bookmark_rounded,
      emoji: '💾',
      title: 'Always Works,\nEven Offline',
      subtitle:
          'Save any recipe to your offline kitchen. No Wi-Fi? No problem. Your favourites are always there.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    debugPrint('[OnboardingPage] init, ${_slides.length} slides');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      debugPrint('[OnboardingPage] get started tapped');
      context.go(AppRoutes.login);
    }
  }

  void _skip() {
    debugPrint('[OnboardingPage] skip tapped');
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[OnboardingPage] build index=$_currentIndex');
    final slide = _slides[_currentIndex];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [slide.gradientStart, slide.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: _currentIndex < _slides.length - 1
                      ? TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        )
                      : const SizedBox(height: 40),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) {
                    setState(() => _currentIndex = i);
                    debugPrint('[OnboardingPage] page changed to $i');
                  },
                  itemBuilder: (_, i) => _SlideContent(slide: _slides[i]),
                ),
              ),

              // Bottom section
              Padding(
                padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 40.h),
                child: Column(
                  children: [
                    // Dot indicator
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _slides.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 8.w,
                        dotHeight: 8.h,
                        expansionFactor: 3,
                        spacing: 6.w,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: slide.gradientStart,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          _currentIndex < _slides.length - 1
                              ? 'Next'
                              : 'Get Started',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final Color gradientStart;
  final Color gradientEnd;
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.gradientStart,
    required this.gradientEnd,
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                child: Center(
                  child: Text(
                    slide.emoji,
                    style: TextStyle(fontSize: 54.sp),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 48.h),
          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: 16.h),
          // Subtitle
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:test/src/rust/api/simple.dart';
import 'package:test/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isComputing = false;
  String currentOperation = '';
  String currentSize = '';

  String _calculateFibonacciDart(int n) {
    final stopwatch = Stopwatch()..start();
    BigInt prev = BigInt.zero;
    BigInt current = BigInt.one;

    if (n <= 1) {
      return "Result: $n\nTime taken: ${stopwatch.elapsed}";
    }

    for (var i = 1; i < n; i++) {
      final next = prev + current;
      prev = current;
      current = next;
    }

    stopwatch.stop();
    return "Result: $current\nTime taken: ${stopwatch.elapsed}";
  }

  String _heavyComputeDart(int size) {
    // Pre-allocate matrices before starting the timer
    final matrix1 = List.generate(size, (_) => List.filled(size, 1.0));
    final matrix2 = List.generate(size, (_) => List.filled(size, 2.0));
    final result = List.generate(size, (_) => List.filled(size, 0.0));

    // Start timing only the computation
    final stopwatch = Stopwatch()..start();

    // Perform matrix multiplication 1000 times to match Rust implementation
    for (var iter = 0; iter < 1000; iter++) {
      // Reset result matrix for next iteration
      for (var i = 0; i < size; i++) {
        for (var j = 0; j < size; j++) {
          result[i][j] = 0.0;
        }
      }

      // Perform matrix multiplication with cache-friendly access pattern
      for (var i = 0; i < size; i++) {
        for (var k = 0; k < size; k++) {
          final m1Ik = matrix1[i][k];
          for (var j = 0; j < size; j++) {
            result[i][j] += m1Ik * matrix2[k][j];
          }
        }
      }
    }

    // Calculate checksum
    var checksum = 0.0;
    for (var row in result) {
      for (var val in row) {
        checksum += val;
      }
    }

    stopwatch.stop();
    final totalDuration = stopwatch.elapsed;
    final avgDuration =
        Duration(microseconds: totalDuration.inMicroseconds ~/ 1000);
    return "Checksum: ${checksum.toStringAsFixed(2)}\nTime taken for 1000 iterations: $totalDuration\nAverage time per iteration: $avgDuration";
  }

  Future<void> runFibonacciBenchmark() async {
    try {
      setState(() {
        isComputing = true;
        currentOperation = 'Initializing...';
      });

      const numbers = [1000, 5000, 10000, 30000];
      final results = <Widget>[];

      for (final n in numbers) {
        setState(() {
          currentSize = '$n';
        });

        // Rust computation
        setState(() {
          currentOperation = 'Running Rust implementation...';
        });
        String? rustResult;
        Duration? rustDuration;
        try {
          final rustStart = DateTime.now();
          rustResult = calculateFibonacci(n: n);
          rustDuration = DateTime.now().difference(rustStart);
        } catch (e) {
          print('Error in Rust computation: $e');
          rustResult = 'Error: $e';
          rustDuration = Duration.zero;
        }

        // Dart computation
        setState(() {
          currentOperation = 'Running Dart implementation...';
        });
        String? dartResult;
        Duration? dartDuration;
        try {
          final dartStart = DateTime.now();
          dartResult = _calculateFibonacciDart(n);
          dartDuration = DateTime.now().difference(dartStart);
        } catch (e) {
          print('Error in Dart computation: $e');
          dartResult = 'Error: $e';
          dartDuration = Duration.zero;
        }

        results.addAll([
          Text('Fibonacci($n):',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const SizedBox(height: 8),
          Text(
              'Rust: ${rustDuration?.inMilliseconds ?? "error"}ms\n$rustResult',
              style: const TextStyle(color: Colors.green)),
          Text(
              'Dart: ${dartDuration?.inMilliseconds ?? "error"}ms\n$dartResult',
              style: const TextStyle(color: Colors.orange)),
          const SizedBox(height: 16),
        ]);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Performance Comparison',
                style: TextStyle(fontSize: 20)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: results,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        isComputing = false;
        currentOperation = '';
        currentSize = '';
      });
    }
  }

  Future<void> runMatrixBenchmark() async {
    setState(() {
      isComputing = true;
      currentOperation = 'Initializing...';
    });

    const sizes = [100, 200, 300];
    final results = <Widget>[];

    try {
      for (final size in sizes) {
        setState(() {
          currentSize = '${size}x${size}';
        });

        // Rust computation
        setState(() {
          currentOperation = 'Running Rust implementation...';
        });
        final rustStart = DateTime.now();
        final rustResult = heavyCompute(size: size);
        final rustDuration = DateTime.now().difference(rustStart);
        print('Matrix ${size}x${size} - Rust Implementation:');
        print('Time taken: ${rustDuration.inMilliseconds}ms');
        print('Result: $rustResult\n');

        // Dart computation
        setState(() {
          currentOperation = 'Running Dart implementation...';
        });
        final dartStart = DateTime.now();
        final dartResult = _heavyComputeDart(size);
        final dartDuration = DateTime.now().difference(dartStart);
        print('Matrix ${size}x${size} - Dart Implementation:');
        print('Time taken: ${dartDuration.inMilliseconds}ms');
        print('Result: $dartResult\n');
        print(
            'Speed Difference: ${(dartDuration.inMilliseconds / rustDuration.inMilliseconds).toStringAsFixed(2)}x\n');

        results.addAll([
          Text('Matrix Size: ${size}x${size}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const SizedBox(height: 8),
          Text('Rust: ${rustDuration.inMilliseconds}ms',
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
          Text('Dart: ${dartDuration.inMilliseconds}ms',
              style: const TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'Speed Difference: ${(dartDuration.inMilliseconds / rustDuration.inMilliseconds).toStringAsFixed(2)}x',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          const SizedBox(height: 16),
        ]);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Matrix Multiplication Benchmark',
                style: TextStyle(fontSize: 20)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: results,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        isComputing = false;
        currentOperation = '';
        currentSize = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rust vs Dart Performance'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isComputing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Current Operation: $currentOperation',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Current Size: $currentSize',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 32),
              ],
              ElevatedButton(
                onPressed: isComputing ? null : runFibonacciBenchmark,
                child: const Text('Compare Performance'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isComputing ? null : runMatrixBenchmark,
                child: const Text('Run Matrix Multiplication Benchmark'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

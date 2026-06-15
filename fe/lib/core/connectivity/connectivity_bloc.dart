import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../websocket/websocket_client.dart';

// ─── Events ────────────────────────────────────────────────────────────────

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  @override
  List<Object?> get props => [];
}

class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

class ConnectivityChanged extends ConnectivityEvent {
  final bool isConnected;
  const ConnectivityChanged(this.isConnected);
  @override
  List<Object?> get props => [isConnected];
}

class WebSocketConnected extends ConnectivityEvent {
  const WebSocketConnected();
}

// ─── States ───────────────────────────────────────────────────────────────

enum ConnectivityStatus { offline, connecting, online }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;

  const ConnectivityState({this.status = ConnectivityStatus.connecting});

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  ConnectivityState copyWith({ConnectivityStatus? status}) {
    return ConnectivityState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final WebSocketClient _wsClient;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _wsSub;

  ConnectivityBloc({
    required WebSocketClient wsClient,
  })  : _wsClient = wsClient,
        super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityChanged>(_onChanged);
    on<WebSocketConnected>(_onWsConnected);
  }

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    // Theo dõi connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      add(ConnectivityChanged(hasConnection));
    });

    // Theo dõi WebSocket connection state
    _wsSub = _wsClient.connectionStream.listen((connected) {
      if (connected) {
        _wsClient.resume();
        add(const WebSocketConnected());
      }
    });

    // Kiểm tra trạng thái ban đầu
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    emit(state.copyWith(
      status: hasConnection
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline,
    ));
  }

  void _onChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    if (event.isConnected) {
      emit(state.copyWith(status: ConnectivityStatus.connecting));
      _wsClient.resume();
      emit(state.copyWith(status: ConnectivityStatus.online));
    } else {
      emit(state.copyWith(status: ConnectivityStatus.offline));
    }
  }

  void _onWsConnected(
    WebSocketConnected event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(state.copyWith(status: ConnectivityStatus.online));
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _wsSub?.cancel();
    return super.close();
  }
}

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pot_g/app/modules/common/presentation/utils/log.dart';
import 'package:pot_g/app/modules/core/domain/repositories/link_repository.dart';

part 'link_bloc.freezed.dart';

@injectable
class LinkBloc extends Bloc<LinkEvent, LinkState> {
  final LinkRepository _repository;

  LinkBloc(this._repository) : super(const LinkState.initial()) {
    on<_Init>((event, emit) {
      emit(const LinkState.loading());
      return emit.forEach(
        _repository.getLinkStream().expand((event) => [null, event]),
        onData: (state) {
          if (state == null) return const _Initial();
          // 전체 URI와 path를 모두 포함
          try {
            final uri = Uri.parse(state);
            return _Loaded(link: uri.path, fullUri: state);
          } catch (e) {
            // URI 파싱 실패 시 원본 문자열 반환
            return _Loaded(link: state, fullUri: state);
          }
        },
        onError: (error, stackTrace) {
          L.e(error, stackTrace);
          return const _Error();
        },
      );
    }, transformer: restartable());
  }
}

@freezed
class LinkEvent with _$LinkEvent {
  const factory LinkEvent.init() = _Init;
}

@freezed
class LinkState with _$LinkState {
  const factory LinkState.initial() = _Initial;
  const factory LinkState.loading() = _Loading;
  const factory LinkState.loaded({
    required String link,
    String? fullUri,
  }) = _Loaded;
  const factory LinkState.error() = _Error;
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/tenant_repository.dart';
import 'tenant_event.dart';
import 'tenant_state.dart';

class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final TenantRepository _repository;

  TenantBloc(this._repository) : super(TenantInitial()) {
    on<LoadCachedTenantEvent>(_onLoadCachedTenant);
    on<LookupTenantEvent>(_onLookupTenant);
    on<ClearTenantEvent>(_onClearTenant);
  }

  void _onLoadCachedTenant(LoadCachedTenantEvent event, Emitter<TenantState> emit) {
    final cached = _repository.getCachedTenant();
    if (cached != null) {
      emit(TenantSelected(cached));
    } else {
      emit(TenantInitial());
    }
  }

  Future<void> _onLookupTenant(LookupTenantEvent event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      final tenant = await _repository.lookupTenant(event.code);
      emit(TenantSelected(tenant));
    } catch (e) {
      emit(TenantError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onClearTenant(ClearTenantEvent event, Emitter<TenantState> emit) async {
    await _repository.clearTenant();
    emit(TenantInitial());
  }
}

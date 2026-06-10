import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../shared/widgets/premium_widgets.dart';

// Tipos que activan la sección de intervención técnica
const _kTiposMantenimiento = ['Mantenimiento', 'Soporte Técnico', 'Impresora / Fotocopiadora', 'Reparaciones Generales'];

class ReporteTecnicoScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String jobId;
  final List<String> servicios;

  const ReporteTecnicoScreen({
    super.key,
    required this.userData,
    required this.jobId,
    required this.servicios,
  });

  @override
  State<ReporteTecnicoScreen> createState() => _ReporteTecnicoScreenState();
}

class _ReporteTecnicoScreenState extends State<ReporteTecnicoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  final _cedulaEncargadoCtrl = TextEditingController();

  // ─── Sección Mantenimiento ───────────────────────────────────────────────
  final List<Map<String, TextEditingController>> _equipos = [];
  final List<Map<String, TextEditingController>> _detalles = [];
  final List<Map<String, TextEditingController>> _insumos = [];

  // ─── Sección Alquiler ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _alquileres = [];

  // ─── Sección Venta ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _ventas = [];

  // ─── Sección Toma de Contador ────────────────────────────────────────────
  final List<Map<String, TextEditingController>> _contadores = [];

  // ─── Liquidación ─────────────────────────────────────────────────────────
  final _costoEmpresaCtrl = TextEditingController();
  final _costoTecnicoCtrl = TextEditingController();

  bool _mostrarMantenimiento = false;
  bool _mostrarAlquiler = false;
  bool _mostrarVenta = false;
  bool _mostrarContador = false;

  @override
  void initState() {
    super.initState();
    _mostrarMantenimiento = widget.servicios.any((s) => _kTiposMantenimiento.contains(s));
    _mostrarAlquiler = widget.servicios.contains('Alquiler de Máquina');
    _mostrarVenta = widget.servicios.contains('Venta de Máquina');

    if (_mostrarMantenimiento) {
      _addEquipo();
      _addDetalle();
      _addInsumo();
    }
    if (_mostrarAlquiler) _addAlquiler();
    if (_mostrarVenta) _addVenta();
  }

  // ── Helpers add/remove ───────────────────────────────────────────────────

  void _addEquipo() => setState(() => _equipos.add({
        'equipoMarca': TextEditingController(),
        'modelo': TextEditingController(),
      }));

  void _removeEquipo(int i) {
    if (_equipos.length > 1) {
      for (final c in _equipos[i].values) { c.dispose(); }
      setState(() => _equipos.removeAt(i));
    }
  }

  void _addDetalle() => setState(() => _detalles.add({
        'diagnostico': TextEditingController(),
        'solucion': TextEditingController(),
      }));

  void _removeDetalle(int i) {
    if (_detalles.length > 1) {
      for (final c in _detalles[i].values) { c.dispose(); }
      setState(() => _detalles.removeAt(i));
    }
  }

  void _addInsumo() => setState(() => _insumos.add({
        'descripcion': TextEditingController(),
        'cantidad': TextEditingController(),
      }));

  void _removeInsumo(int i) {
    if (_insumos.length > 1) {
      for (final c in _insumos[i].values) { c.dispose(); }
      setState(() => _insumos.removeAt(i));
    }
  }

  void _addAlquiler() => setState(() => _alquileres.add({
        'marcaModelo': TextEditingController(),
        'serial': TextEditingController(),
        'serialInterno': TextEditingController(),
        'contadorInicial': TextEditingController(),
        'valorMensual': TextEditingController(),
        'copiasIncluidas': TextEditingController(),
        'valorCopiaExtra': TextEditingController(),
        'fechaInicio': TextEditingController(),
        'duracion': TextEditingController(),
        'condicionesEquipo': TextEditingController(),
        'tieneEstabilizador': 'Sí',
        'equipoFuncionando': 'Sí',
        'capacitacion': 'Sí',
        'observaciones': TextEditingController(),
      }));

  void _removeAlquiler(int i) {
    if (_alquileres.length > 1) {
      for (final c in _alquileres[i].values) { if (c is TextEditingController) c.dispose(); }
      setState(() => _alquileres.removeAt(i));
    } else {
      setState(() {
        for (final c in _alquileres[0].values) { if (c is TextEditingController) c.dispose(); }
        _alquileres.clear();
        _mostrarAlquiler = false;
      });
    }
  }

  void _addVenta() => setState(() => _ventas.add({
        'marcaModelo': TextEditingController(),
        'serial': TextEditingController(),
        'serialInterno': TextEditingController(),
        'estado': 'Nuevo',
        'precio': TextEditingController(),
        'formaPago': 'Contado',
        'garantia': TextEditingController(),
        'condicionesEquipo': TextEditingController(),
        'tieneEstabilizador': 'Sí',
        'equipoFuncionando': 'Sí',
        'capacitacion': 'Sí',
        'accesorios': TextEditingController(),
      }));

  void _removeVenta(int i) {
    if (_ventas.length > 1) {
      for (final c in _ventas[i].values) { if (c is TextEditingController) c.dispose(); }
      setState(() => _ventas.removeAt(i));
    } else {
      setState(() {
        for (final c in _ventas[0].values) { if (c is TextEditingController) c.dispose(); }
        _ventas.clear();
        _mostrarVenta = false;
      });
    }
  }

  void _addContador() => setState(() => _contadores.add({
        'equipo': TextEditingController(),
        'contador': TextEditingController(),
        'observaciones': TextEditingController(),
      }));

  void _removeContador(int i) {
    if (_contadores.length > 1) {
      for (final c in _contadores[i].values) { c.dispose(); }
      setState(() => _contadores.removeAt(i));
    } else {
      setState(() {
        for (final c in _contadores[0].values) { c.dispose(); }
        _contadores.clear();
        _mostrarContador = false;
      });
    }
  }

  void _activarSeccion(String tipo) {
    if (tipo == 'mantenimiento' && !_mostrarMantenimiento) {
      setState(() {
        _mostrarMantenimiento = true;
        _addEquipo();
        _addDetalle();
        _addInsumo();
      });
    } else if (tipo == 'alquiler') {
      if (!_mostrarAlquiler) setState(() { _mostrarAlquiler = true; });
      _addAlquiler();
    } else if (tipo == 'venta') {
      if (!_mostrarVenta) setState(() { _mostrarVenta = true; });
      _addVenta();
    } else if (tipo == 'contador') {
      if (!_mostrarContador) setState(() { _mostrarContador = true; });
      _addContador();
    }
  }

  @override
  void dispose() {
    _cedulaEncargadoCtrl.dispose();
    _costoEmpresaCtrl.dispose();
    _costoTecnicoCtrl.dispose();
    for (final m in [..._equipos, ..._detalles, ..._insumos]) {
      for (final c in m.values) { c.dispose(); }
    }
    for (final m in [..._alquileres, ..._ventas]) {
      for (final c in m.values) { if (c is TextEditingController) c.dispose(); }
    }
    for (final m in _contadores) {
      for (final c in m.values) { c.dispose(); }
    }
    super.dispose();
  }

  Future<void> _enviarReporte() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete los campos obligatorios')));
      return;
    }

    setState(() => _isSending = true);
    try {
      final List<String> serviciosFinales = [...widget.servicios];
      if (_mostrarMantenimiento && !serviciosFinales.any((s) => _kTiposMantenimiento.contains(s))) {
        serviciosFinales.add('Mantenimiento');
      }
      if (_mostrarAlquiler && !serviciosFinales.contains('Alquiler de Máquina')) {
        serviciosFinales.add('Alquiler de Máquina');
      }
      if (_mostrarVenta && !serviciosFinales.contains('Venta de Máquina')) {
        serviciosFinales.add('Venta de Máquina');
      }

      final reporte = <String, dynamic>{
        'encargadoNombre': widget.userData['nombre'],
        'encargadoCedula': _cedulaEncargadoCtrl.text.trim(),
        'tipoServicio': serviciosFinales.join(' + '),
        'servicios': serviciosFinales,
        'costoEmpresa': double.tryParse(_costoEmpresaCtrl.text.trim()) ?? 0.0,
        'costoTecnico': double.tryParse(_costoTecnicoCtrl.text.trim()) ?? 0.0,
        'fechaEmision': FieldValue.serverTimestamp(),
      };

      if (_mostrarMantenimiento) {
        reporte['equipos'] = _equipos.map((e) => {
          'equipoMarca': e['equipoMarca']!.text.trim(),
          'modelo': e['modelo']!.text.trim(),
        }).toList();
        reporte['detallesTecnicos'] = _detalles.map((d) => {
          'diagnostico': d['diagnostico']!.text.trim(),
          'solucion': d['solucion']!.text.trim(),
        }).toList();
        reporte['insumos'] = _insumos.map((i) => {
          'descripcion': i['descripcion']!.text.trim(),
          'cantidad': i['cantidad']!.text.trim(),
        }).toList();
      }

      if (_mostrarAlquiler && _alquileres.isNotEmpty) {
        reporte['alquileres'] = _alquileres.map((alq) => {
          'marcaModelo': alq['marcaModelo']!.text.trim(),
          'serial': alq['serial']!.text.trim(),
          'serialInterno': alq['serialInterno']!.text.trim(),
          'contadorInicial': alq['contadorInicial']!.text.trim(),
          'valorMensual': double.tryParse(alq['valorMensual']!.text.trim()) ?? 0.0,
          'copiasIncluidas': int.tryParse(alq['copiasIncluidas']!.text.trim()) ?? 0,
          'valorCopiaExtra': double.tryParse(alq['valorCopiaExtra']!.text.trim()) ?? 0.0,
          'fechaInicio': alq['fechaInicio']!.text.trim(),
          'duracionMeses': int.tryParse(alq['duracion']!.text.trim()) ?? 0,
          'condicionesEquipo': alq['condicionesEquipo']!.text.trim(),
          'tieneEstabilizador': alq['tieneEstabilizador'],
          'equipoFuncionando': alq['equipoFuncionando'],
          'capacitacion': alq['capacitacion'],
          'observaciones': alq['observaciones']!.text.trim(),
        }).toList();
      }

      if (_mostrarVenta && _ventas.isNotEmpty) {
        reporte['ventas'] = _ventas.map((vnt) => {
          'marcaModelo': vnt['marcaModelo']!.text.trim(),
          'serial': vnt['serial']!.text.trim(),
          'serialInterno': vnt['serialInterno']!.text.trim(),
          'estado': vnt['estado'],
          'precio': double.tryParse(vnt['precio']!.text.trim()) ?? 0.0,
          'formaPago': vnt['formaPago'],
          'garantia': vnt['garantia']!.text.trim(),
          'condicionesEquipo': vnt['condicionesEquipo']!.text.trim(),
          'tieneEstabilizador': vnt['tieneEstabilizador'],
          'equipoFuncionando': vnt['equipoFuncionando'],
          'capacitacion': vnt['capacitacion'],
          'accesorios': vnt['accesorios']!.text.trim(),
        }).toList();
      }

      if (_mostrarContador && _contadores.isNotEmpty) {
        reporte['contadoresToma'] = _contadores.map((cnt) => {
          'equipo': cnt['equipo']!.text.trim(),
          'contador': cnt['contador']!.text.trim(),
          'observaciones': cnt['observaciones']!.text.trim(),
        }).toList();
      }

      await FirebaseFirestore.instance.collection('trabajos').doc(widget.jobId).update({
        'estado': 'revision_cliente',
        'reporteTecnico': reporte,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado al cliente'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Generar Reporte Técnico', subtitle: 'Constancia de servicio para el cliente'),

              // Servicios del ticket
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cFucsia.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cFucsia.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_rounded, color: cFucsia, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.servicios.join(' · '),
                        style: const TextStyle(color: cFucsia, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Datos del técnico ──────────────────────────────────────────
              PremiumCard(
                accentColor: cFucsia,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INFO DEL TÉCNICO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextFormField(initialValue: widget.userData['nombre'], decoration: const InputDecoration(labelText: 'Nombre Completo'), readOnly: true),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cedulaEncargadoCtrl,
                      decoration: const InputDecoration(labelText: 'Cédula N°', hintText: 'Ingrese su identificación'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),

              // ── Sección Mantenimiento / Soporte / Impresora / Reparación ──
              if (_mostrarMantenimiento) ...[
                _buildDynamicSection('Equipos Intervenidos', _equipos, _addEquipo, _removeEquipo, (i) => [
                  TextFormField(controller: _equipos[i]['equipoMarca'], decoration: const InputDecoration(labelText: 'Equipo / Marca'), validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _equipos[i]['modelo'], decoration: const InputDecoration(labelText: 'Modelo')),
                ]),
                _buildDynamicSection('Trabajo Realizado', _detalles, _addDetalle, _removeDetalle, (i) => [
                  TextFormField(controller: _detalles[i]['diagnostico'], decoration: const InputDecoration(labelText: 'Diagnóstico'), validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _detalles[i]['solucion'], decoration: const InputDecoration(labelText: 'Solución Técnica'), maxLines: 2),
                ]),
                _buildDynamicSection('Insumos Utilizados', _insumos, _addInsumo, _removeInsumo, (i) => [
                  TextFormField(controller: _insumos[i]['descripcion'], decoration: const InputDecoration(labelText: 'Descripción del Insumo')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _insumos[i]['cantidad'], decoration: const InputDecoration(labelText: 'Cantidad'), keyboardType: TextInputType.number),
                ]),
              ],

              // ── Sección Alquiler de Máquina ────────────────────────────────
              if (_mostrarAlquiler && _alquileres.isNotEmpty) ...[
                _buildDynamicSection('Contratos de Alquiler', _alquileres, _addAlquiler, _removeAlquiler, (i) => [
                  const Text('DETALLES DEL CONTRATO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cFucsia)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _alquileres[i]['marcaModelo'], decoration: const InputDecoration(labelText: 'Marca / Modelo'), validator: (v) => v!.trim().isEmpty ? 'Requerido' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _alquileres[i]['serial'], decoration: const InputDecoration(labelText: 'Serial Fabricante'))),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(controller: _alquileres[i]['serialInterno'], decoration: const InputDecoration(labelText: 'Serial Interno (Empresa)', hintText: 'Código interno')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _alquileres[i]['contadorInicial'], decoration: const InputDecoration(labelText: 'Contador Inicial'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _alquileres[i]['valorMensual'], decoration: const InputDecoration(labelText: 'Valor Mensual (\$)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _alquileres[i]['copiasIncluidas'], decoration: const InputDecoration(labelText: 'Copias Incluidas/Mes'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _alquileres[i]['valorCopiaExtra'], decoration: const InputDecoration(labelText: 'Valor Copia Extra (\$)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _alquileres[i]['fechaInicio'],
                      decoration: const InputDecoration(labelText: 'Fecha Inicio', hintText: 'AAAA-MM-DD'),
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2040));
                        if (picked != null) _alquileres[i]['fechaInicio']!.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
                      },
                      readOnly: true,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _alquileres[i]['duracion'], decoration: const InputDecoration(labelText: 'Duración (meses)'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 16),
                  // Entrega de Equipo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cFucsia.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cFucsia.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.inventory_2_rounded, color: cFucsia, size: 14),
                          SizedBox(width: 6),
                          Text('ENTREGA DE EQUIPO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cFucsia)),
                        ]),
                        const SizedBox(height: 12),
                        TextFormField(controller: _alquileres[i]['condicionesEquipo'], decoration: const InputDecoration(labelText: 'Condiciones del Equipo al Entregarlo')),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildDropdownSiNo('Cliente tiene estabilizador', _alquileres[i]['tieneEstabilizador'] as String, (v) => setState(() => _alquileres[i]['tieneEstabilizador'] = v!))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdownSiNo('Equipo funcionando', _alquileres[i]['equipoFuncionando'] as String, (v) => setState(() => _alquileres[i]['equipoFuncionando'] = v!))),
                        ]),
                        const SizedBox(height: 12),
                        _buildDropdownSiNo('Capacitación al cliente', _alquileres[i]['capacitacion'] as String, (v) => setState(() => _alquileres[i]['capacitacion'] = v!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _alquileres[i]['observaciones'], decoration: const InputDecoration(labelText: 'Observaciones del Contrato'), maxLines: 2),
                ]),
              ],

              // ── Sección Venta de Máquina ───────────────────────────────────
              if (_mostrarVenta && _ventas.isNotEmpty) ...[
                _buildDynamicSection('Detalles de Venta', _ventas, _addVenta, _removeVenta, (i) => [
                  const Text('DATOS DE LA VENTA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cFucsia)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _ventas[i]['marcaModelo'], decoration: const InputDecoration(labelText: 'Marca / Modelo'), validator: (v) => v!.trim().isEmpty ? 'Requerido' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _ventas[i]['serial'], decoration: const InputDecoration(labelText: 'Serial Fabricante'))),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(controller: _ventas[i]['serialInterno'], decoration: const InputDecoration(labelText: 'Serial Interno (Empresa)', hintText: 'Código interno')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _ventas[i]['estado'] as String,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: ['Nuevo', 'Reacondicionado', 'Usado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _ventas[i]['estado'] = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _ventas[i]['precio'], decoration: const InputDecoration(labelText: 'Precio de Venta (\$)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _ventas[i]['formaPago'] as String,
                      decoration: const InputDecoration(labelText: 'Forma de Pago'),
                      items: ['Contado', 'Financiado / Cuotas', 'Transferencia Bancaria'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _ventas[i]['formaPago'] = v!),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _ventas[i]['garantia'], decoration: const InputDecoration(labelText: 'Garantía', hintText: 'Ej: 6 meses'))),
                  ]),
                  const SizedBox(height: 16),
                  // Entrega de Equipo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cFucsia.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cFucsia.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.inventory_2_rounded, color: cFucsia, size: 14),
                          SizedBox(width: 6),
                          Text('ENTREGA DE EQUIPO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cFucsia)),
                        ]),
                        const SizedBox(height: 12),
                        TextFormField(controller: _ventas[i]['condicionesEquipo'], decoration: const InputDecoration(labelText: 'Condiciones del Equipo al Entregarlo')),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildDropdownSiNo('Cliente tiene estabilizador', _ventas[i]['tieneEstabilizador'] as String, (v) => setState(() => _ventas[i]['tieneEstabilizador'] = v!))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdownSiNo('Equipo funcionando', _ventas[i]['equipoFuncionando'] as String, (v) => setState(() => _ventas[i]['equipoFuncionando'] = v!))),
                        ]),
                        const SizedBox(height: 12),
                        _buildDropdownSiNo('Capacitación al cliente', _ventas[i]['capacitacion'] as String, (v) => setState(() => _ventas[i]['capacitacion'] = v!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _ventas[i]['accesorios'], decoration: const InputDecoration(labelText: 'Accesorios / Incluidos'), maxLines: 2),
                ]),
              ],

              // ── Sección Toma de Contador ───────────────────────────────────
              if (_mostrarContador && _contadores.isNotEmpty) ...[
                _buildDynamicSection('Toma de Contador', _contadores, _addContador, _removeContador, (i) => [
                  const Text('LECTURA DE CONTADOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cFucsia)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _contadores[i]['equipo'], decoration: const InputDecoration(labelText: 'Equipo (Marca / Modelo)'), validator: (v) => v!.trim().isEmpty ? 'Requerido' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _contadores[i]['contador'], decoration: const InputDecoration(labelText: 'Contador Actual'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(controller: _contadores[i]['observaciones'], decoration: const InputDecoration(labelText: 'Observaciones (opcional)'), maxLines: 2),
                ]),
              ],

              // ── BOTÓN: Agregar sección extra ──────────────────────────────
              _buildAgregarSeccionWidget(),

              // ── Liquidación ───────────────────────────────────────────────
              PremiumCard(
                accentColor: cAmarillo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LIQUIDACIÓN DE SERVICIOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _costoEmpresaCtrl, decoration: const InputDecoration(labelText: 'Costo Empresa (\$)', hintText: '0'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _costoTecnicoCtrl, decoration: const InputDecoration(labelText: 'Costo Técnico (\$)', hintText: '0'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: cFucsia),
                  onPressed: _isSending ? null : _enviarReporte,
                  icon: _isSending ? const SizedBox() : const Icon(Icons.send_rounded, color: Colors.white),
                  label: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ENVIAR REPORTE AL CLIENTE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper: dropdown Sí / No
  Widget _buildDropdownSiNo(String label, String value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: ['Sí', 'No'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  /// Botones para agregar secciones que no estaban en el ticket
  Widget _buildAgregarSeccionWidget() {
    final opciones = <Map<String, dynamic>>[];
    if (!_mostrarMantenimiento) {
      opciones.add({'label': 'Mantenimiento / Soporte', 'icon': Icons.build_rounded, 'tipo': 'mantenimiento'});
    }
    opciones.add({'label': 'Agregar Contrato Alquiler', 'icon': Icons.article_rounded, 'tipo': 'alquiler'});
    opciones.add({'label': 'Agregar Venta de Máquina', 'icon': Icons.point_of_sale_rounded, 'tipo': 'venta'});
    opciones.add({'label': 'Toma de Contador', 'icon': Icons.speed_rounded, 'tipo': 'contador'});

    if (opciones.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AGREGAR SECCIÓN AL REPORTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: opciones.map((op) {
              return OutlinedButton.icon(
                onPressed: () => _activarSeccion(op['tipo'] as String),
                icon: Icon(op['icon'] as IconData, size: 16, color: cFucsia),
                label: Text(op['label'] as String, style: const TextStyle(fontSize: 12, color: cFucsia)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cFucsia.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSection(String title, List items, VoidCallback onAdd, void Function(int) onRemove, List<Widget> Function(int) builder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: SectionHeader(title: title)),
            IconButton(icon: const Icon(Icons.add_circle_rounded, color: cFucsia), onPressed: onAdd),
          ],
        ),
        for (int i = 0; i < items.length; i++) ...[
          PremiumCard(
            accentColor: cFucsia.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => onRemove(i),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                    ),
                  ),
                ),
                ...builder(i),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

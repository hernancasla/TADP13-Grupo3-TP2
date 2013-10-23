require_relative '../src/advice'

class AbstractCache

  @@cache = Array.new

  def self.cache
    @@cache
  end

  def self.advice
    cachearODevolverCacheado = Proc.new {
        |clase, simbolo, simboloOriginal, instancia, *args|
      invocacion = invocacionCacheada(clase, simbolo, instancia, args)
      invocacion_cacheada = AbstractCache.cache.detect {|cached| cached.eql? invocacion}
      unless invocacion_cacheada.nil?
        next invocacion_cacheada.resultado
      else
        resultado = instancia.send simboloOriginal, *args
        invocacion.resultado = resultado
        AbstractCache.cache << invocacion
      end
      resultado
    }
    AdviceEnLugarDe.new(cachearODevolverCacheado)
  end

  def self.invocacionCacheada(clase, simbolo, instancia, args)
    raise :subclass_responsability
  end

end

class StatelessCache < AbstractCache

  InvocacionCacheadaSinEstado = Struct.new(:clase, :simbolo, :args, :resultado) do
    def eql?(other)
      (clase.eql? other.clase) and (simbolo.eql? other.simbolo) and (args.eql? other.args)
    end
  end

  def self.invocacionCacheada(clase, simbolo, instancia, args)
    InvocacionCacheadaSinEstado.new(clase, simbolo, args)
  end

end

class StatefulCache < AbstractCache

  InvocacionCacheadaConEstado = Struct.new(:clase, :simbolo, :instancia, :args, :resultado) do
    def eql?(other)
      (clase.eql? other.clase) and (simbolo.eql? other.simbolo) and (args.eql? other.args) and (compare_instances?(instancia,other.instancia))
    end
    def compare_instances?(cacheado, objeto)
      variablesDeCacheado = cacheado.instance_variables
      variablesDeObjeto = objeto.instance_variables
      diferenciasEntreVariables = (variablesDeCacheado - variablesDeObjeto) and (variablesDeObjeto - variablesDeCacheado)
      if (diferenciasEntreVariables) == []
        variablesDeCacheado.all? {
            |variable|
          cacheado.instance_variable_get(variable).eql?(objeto.instance_variable_get(variable))
        }
      else
        false
      end
    end
  end

  def self.invocacionCacheada(clase, simbolo, instancia, args)
    InvocacionCacheadaConEstado.new(clase, simbolo, instancia, args)
  end

end
# encoding: UTF-8

class ViteFait

  def self.calcul_coefficiant_diction
    paragraphes = <<-EOT
Lorem ipsum dolor sit amet, consectetur adipiscing elit.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque massa mi, dictum a nisi sit amet, lacinia tempus nibh. Vestibulum hendrerit interdum erat, eget feugiat elit interdum gravida.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque massa mi, dictum a nisi sit amet, lacinia tempus nibh. Vestibulum hendrerit interdum erat, eget feugiat elit interdum gravida. Ut libero odio, vestibulum congue hendrerit ut, lacinia volutpat nisl. Integer at tristique massa, id mattis lorem. Donec in tortor scelerisque turpis vehicula iaculis. Aliquam rhoncus mattis orci, sit amet luctus orci congue eu. Ut semper eros eget elit tristique consectetur.

Nulla facilisi. Mauris in malesuada augue, id pharetra arcu. Suspendisse sit amet lectus molestie, eleifend lacus ut, interdum leo. Donec nec ultricies dui. Praesent volutpat augue eget felis dictum vehicula. Maecenas volutpat, lectus eget congue placerat, nunc ipsum rutrum metus, quis tincidunt libero leo et odio. Fusce laoreet nibh et elementum sodales. Sed finibus nisi eget neque ullamcorper, molestie tristique velit feugiat. Nunc malesuada, neque sit amet elementum dictum, nibh urna tincidunt nisi, et porttitor nibh risus et quam.

Aliquam erat volutpat. Aliquam ultricies pulvinar augue, vel consectetur leo ornare vel. Fusce bibendum lacus ut dolor pharetra, ut aliquet nibh malesuada. Ut mattis sit amet lectus vel rutrum. Praesent luctus sapien vel tristique pretium. Nunc eu dui in ex congue cursus nec porta augue. Duis in urna sapien. In mollis elit a euismod dignissim. Duis finibus sit amet lacus vel tincidunt. Cras vel ultrices lectus.

Cras quis ultricies dui, at dapibus justo. Donec pharetra sapien ac ex interdum gravida. Vivamus viverra ultricies mi, vitae posuere quam mollis quis. Suspendisse varius nec leo non tincidunt. Suspendisse vitae est vel neque accumsan euismod et sit amet tortor. Phasellus quis placerat tellus, accumsan aliquam ante. Cras aliquam posuere tortor et pharetra. Nunc ut ligula fermentum, viverra sapien a, rhoncus dolor. Nullam velit sem, iaculis a dolor dapibus, tempus lobortis nisl. Aliquam erat volutpat. Vestibulum vehicula leo in ultricies accumsan. Proin ut elementum lacus. Curabitur ullamcorper auctor ex, nec ultricies nulla convallis a. Proin bibendum malesuada nunc, ac euismod justo malesuada vitae. Aliquam erat volutpat.

Praesent justo est, feugiat non mi et, blandit egestas dolor. Nam venenatis lobortis odio, vitae pharetra odio sodales quis. Donec sodales at risus eu ullamcorper. In eu ligula ut dui sagittis egestas sit amet quis leo. Curabitur efficitur neque lacus, nec imperdiet ipsum pellentesque sit amet. Vestibulum aliquet, magna at efficitur auctor, risus dolor sodales ipsum, sit amet malesuada ante orci at libero. Morbi luctus congue rhoncus. In ac tempor orci. Ut pulvinar sed nunc vel consequat. Mauris mi sem, dignissim interdum pharetra ultrices, vulputate vitae diam. Phasellus iaculis, neque in laoreet finibus, magna felis tincidunt elit, in facilisis tellus dolor ut nibh.

Phasellus efficitur eu felis in tempus. Quisque a dignissim massa. Cras neque velit, mattis eget justo sed, auctor volutpat turpis. Cras tempus turpis fermentum enim aliquam, at molestie lectus malesuada. Donec eu lacus vestibulum, pulvinar nulla non, sodales tortor. Integer accumsan cursus mauris, id tempus purus. Suspendisse pharetra semper metus mattis semper. Donec a nunc eget eros placerat gravida. Pellentesque pellentesque ligula nibh, vel eleifend quam ultrices nec. Aliquam nec tortor ligula.

Integer bibendum purus ac odio tincidunt, sit amet varius orci faucibus. Praesent dapibus ante ut est maximus, a auctor purus lacinia. Phasellus in lacus malesuada, suscipit elit eu, imperdiet augue. Pellentesque id magna ac quam facilisis volutpat. Suspendisse eu neque ligula. Duis sed tincidunt nisl. Maecenas at erat sed nunc dapibus tempus ut vitae ipsum. Curabitur consequat justo at arcu vehicula efficitur ut eu metus.

Maecenas consequat urna eros, vitae cursus diam porttitor vitae. Morbi placerat ut eros eu dictum. Donec sodales vel risus eget sollicitudin. Cras auctor quam justo, in sodales lorem auctor quis. Donec nec massa ultrices, tincidunt odio quis, elementum urna. Aenean ornare turpis sed erat pharetra ornare. Morbi et dui accumsan, auctor sapien fermentum, blandit purus.

Cras et lacinia urna. Etiam pretium congue felis id viverra. Morbi pharetra consequat ligula non dictum. Morbi turpis justo, porta a tincidunt nec, vehicula quis eros. Curabitur tempor orci sem, sit amet aliquet diam malesuada nec. Nunc consequat sed nulla sit amet placerat. Pellentesque pulvinar ultricies purus vitae scelerisque. Nullam auctor elit nec tincidunt dictum. Proin quis lacus vitae augue vulputate mattis. Donec a mauris enim.

Sed commodo felis quam, ut scelerisque ligula tempor sed.

Sed commodo felis quam, ut scelerisque ligula tempor sed. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Duis ullamcorper pharetra pretium. Duis neque tellus, commodo finibus rutrum sed, elementum et lacus. Mauris mollis ut arcu condimentum interdum. Maecenas non faucibus velit. Integer sit amet purus auctor, fringilla felis quis, hendrerit quam. Morbi eget nunc a magna porttitor tempus. In hac habitasse platea dictumst. Mauris eu nibh congue, iaculis est non, commodo urna.

Nullam non ante in risus gravida feugiat eget sed dolor. Proin nec fermentum massa. Maecenas vestibulum sapien sit amet metus tempor euismod. Mauris tempus velit in lorem condimentum, vitae laoreet erat tempus. Praesent et tellus lectus. Suspendisse dignissim lorem ante, non finibus elit luctus hendrerit. Maecenas facilisis quam ac eros dictum, ac euismod sapien molestie. Etiam blandit diam sem. Fusce rutrum odio ut velit egestas, maximus suscipit enim cursus. Donec ligula nisi, pulvinar quis elementum id, dapibus a ligula. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Phasellus eget tempus ex. Curabitur risus ipsum, accumsan eget diam ut, feugiat pellentesque ligula.

Etiam vitae nisl quis nisi hendrerit fermentum ac ut massa. Etiam posuere luctus est eget lacinia. Mauris tincidunt magna mattis orci molestie ullamcorper. Sed maximus turpis non nisi commodo, ac tempor eros porttitor. Curabitur ut purus sodales, venenatis diam nec, rutrum erat. Morbi viverra dictum augue, id placerat dolor ornare id. Nulla ipsum orci, porta a egestas quis, vestibulum eget neque. Aliquam erat volutpat. Cras ac nulla vel tellus placerat fermentum. Donec dui turpis, varius pulvinar egestas posuere, mollis ac diam. In dignissim nec dui eget imperdiet. Morbi tempor et velit eu malesuada. Nullam ut ullamcorper mi.

Quisque a erat luctus, venenatis sapien a, placerat leo.

Quisque a erat luctus, venenatis sapien a, placerat leo. Integer accumsan fringilla risus id luctus. Pellentesque eget erat tincidunt, varius lacus sit amet, convallis lacus. Pellentesque sem tortor, fermentum sit amet nunc nec, tempor aliquam enim. Integer egestas neque in orci semper, at malesuada orci ullamcorper. Maecenas imperdiet vitae diam in ultrices. Duis bibendum auctor ex vulputate feugiat. Integer gravida gravida lorem, vel consectetur quam maximus vitae. In hac habitasse platea dictumst. Aliquam nibh massa, ultricies ac lacinia sit amet, congue eget eros. Cras fringilla ultrices risus, eget venenatis ante gravida in. Cras ut orci bibendum est blandit sollicitudin sed et nisl.

Ut accumsan ex libero, a iaculis orci auctor nec. Nam nec purus eget orci porttitor tincidunt quis in orci. Proin accumsan venenatis viverra. Vestibulum bibendum tristique sapien, vitae accumsan nisl maximus eu. Mauris a tempor nisl, quis semper neque. Donec vel ultrices erat. Sed ut ante semper, mattis mauris ut, lobortis mi. Suspendisse dictum nisl id augue dictum, id malesuada elit aliquam.

Donec imperdiet nisl quam.

Donec imperdiet nisl quam. Aliquam eget arcu congue, tempor sapien non, ullamcorper mi. Ut et arcu ipsum. Curabitur ut magna vel orci scelerisque vulputate. Nullam euismod consectetur neque, eget mattis elit lacinia a. Vestibulum facilisis orci quis faucibus tristique. Donec placerat dolor ut dui ultricies, et pharetra metus aliquet. Etiam facilisis quis libero et lacinia. Sed lacinia porttitor pellentesque. Vestibulum eget magna et velit volutpat facilisis. Ut sed sagittis augue. Suspendisse ex enim, dignissim et metus non, consequat aliquam tellus. Praesent eget orci quam. Vivamus eu nisl tristique, consectetur tellus sed, suscipit neque. Maecenas sed tellus gravida, lobortis ante non, suscipit neque.

Ut leo risus, cursus vel libero eget, ultrices imperdiet sapien. Praesent enim sapien, pharetra a tortor non, porta hendrerit nisl. Duis turpis risus, viverra ac congue quis, commodo quis nisl. Aliquam pellentesque nunc ac orci dictum blandit. Vestibulum non auctor tortor, nec tincidunt diam. Proin in massa ut tellus placerat maximus quis ac quam. Suspendisse euismod massa sit amet diam lacinia, consectetur ullamcorper elit molestie. In accumsan sagittis sem at dapibus.

Quisque hendrerit augue purus, at pulvinar justo sodales eget. Vestibulum ut libero magna. Pellentesque risus turpis, vulputate sed massa ac, tempor cursus felis. Donec viverra, arcu ac vehicula bibendum, nibh ex euismod magna, cursus ornare orci tortor non ipsum. Vivamus aliquet ligula ut eros faucibus efficitur. Nunc mattis faucibus commodo. Cras tempus consectetur ante quis lacinia. Vivamus gravida neque id consectetur aliquam. Nullam venenatis urna et justo tempor, convallis vulputate nulla interdum. Fusce rutrum ullamcorper orci, id euismod sem lacinia quis. Vivamus ac auctor risus. Aenean pellentesque sagittis rhoncus. Nullam non aliquet turpis.

Duis egestas nec lectus id luctus. Integer rhoncus ligula vel ullamcorper ullamcorper. Duis scelerisque finibus suscipit. Praesent tellus magna, consectetur ac placerat ut, viverra vitae orci. Suspendisse ex tellus, fermentum ut urna in, pellentesque posuere arcu. Aliquam quis orci vitae arcu congue iaculis. Quisque tempus viverra consectetur. Suspendisse tortor erat, convallis non mattis id, rhoncus eget quam. Vivamus blandit rhoncus libero aliquet scelerisque. Cras egestas elit ac justo porta, nec venenatis erat ultricies. Curabitur vel augue sed ante aliquet tincidunt. Morbi id molestie elit. Aenean ut fermentum odio, fringilla fermentum sapien.

Ut sollicitudin ligula eget ultricies ultrices.

Ut sollicitudin ligula eget ultricies ultrices. Nullam imperdiet nec velit at porttitor. Curabitur cursus, justo egestas placerat eleifend, metus massa pretium quam, ac egestas justo lorem eget leo. Donec augue nibh, porta at enim nec, euismod condimentum tellus. Maecenas at consectetur lacus. Morbi laoreet tristique velit ut consectetur. Sed at orci ligula. Cras malesuada, nisl quis placerat cursus, metus turpis fringilla magna, at rutrum eros ligula vel justo. Praesent convallis tellus et libero vestibulum blandit.

In sit amet nisl tincidunt, tristique enim sit amet, sollicitudin dui.

In sit amet nisl tincidunt, tristique enim sit amet, sollicitudin dui. Phasellus nec feugiat orci. Etiam sodales dolor luctus ligula mattis pretium. Pellentesque ultrices est eu aliquet semper. Duis fringilla libero non rhoncus tristique. Ut hendrerit interdum dui, vel efficitur odio aliquet a. Aenean ultrices orci eget eros faucibus egestas. Aenean eget ante ac ligula vehicula semper vel id felis. Nulla sodales nibh lacus, non imperdiet mi sollicitudin varius. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nullam convallis tellus arcu, ac luctus tellus blandit efficitur.
    EOT
    paragraphes = paragraphes.split("\n\n")
    clear
    puts "Nombre de paragraphes : #{paragraphes.count}"

    puts "|                |    Coef.    |    Durée    |    Durée    |    Coef.    |"
    puts "|    longueur    |    Moyen    |   Attendue  |   réelle    |  paragraphe |"
    puts "|------------------------------------------------------------------------|"

    coefs = []
    coef_moyen = nil
    paragraphes.each do |paragraphe|
      len   = paragraphe.length
      duree_expected  = '   ---'
      coef_moyen_s    = '   ---'
      unless coefs.empty?
        coef_moyen = coefs.inject(:+).to_f / coefs.count
        coef_moyen_s = centieme(coef_moyen)
        duree_expected = centieme(len * coef_moyen)
      end
      print "|  #{len.to_s.ljust(14)}|  #{(coef_moyen_s||'---').to_s.ljust(11)}|  #{duree_expected.to_s.ljust(11)}|"
      start_time = Time.now.to_f
      `say -v Audrey "#{paragraphe}"`
      end_time = Time.now.to_f
      duree = end_time - start_time
      duree_s = centieme(duree, 'durée paragraphe')
      coef  = duree / len
      coef_s = centieme(coef)
      puts "  #{duree_s.ljust(11)}|  #{coef_s.ljust(11)}|"
      # On ajoute ce coefficiant
      coefs << coef
    end

    coef_moyen = coefs.inject(:+).to_f / coefs.count
    coef_moyen_s = centieme(coef_moyen)
    puts "COEF_DICTION à #{coef_moyen_s}"
  end

  def self.centieme(x, what = '')
    # puts "#{what} = #{x}"
    e, d = x.to_s.split('.')
    "#{e}.#{d[0..4]}"
  end

end #/ViteFait

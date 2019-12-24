# =begin
#   Essai pour voir comment on peut s'y prendre pour faire les tests
# =end
#
# describe "Une commande" do
#
#   it 'fonctionne avec spawn and pty' do
#
#     # PTY.spawn('./vite-faits.rb liste') do |stdout,stdin,pid|
#     #
#     #   p stdout.read
#     #
#     # end
#
#     pth = File.join(VITEFAIT_CHANTIER_FOLDER, 'tuto-for-test')
#     if File.exists?(pth) && pth.length > 40
#       FileUtils.rm_rf(pth)
#     end
#
#
#     cmd = VFCommand.new('liste')
#     cmd.test do |pty|
#       o = pty.output
#       expect(o).to include('LISTE DES TUTORIELS')
#     end
#
#     cmd = VFCommand.new('list')
#     expect(cmd.test.output).to include('LISTE DES TUTORIELS')
#     expect(cmd.output).to include('=== LISTE DES')
#
#     # Ça, ça fonctionne :
#     # PTY.spawn(' ./vite-faits.rb assistant ') do |stdout, stdin, pid|
#     #   pty = MyPTY.new(stdout, stdin, pid)
#     #
#     #   sleep 0.1
#     #
#     #   expect(File.exists?(pth)).to be false
#     #   pty.tape("tuto-for-test\n")
#     #   sleep 3
#     #   expect(File.exists?(pth)).to be true
#     #
#     # end
#
#
#
#   end
# end
